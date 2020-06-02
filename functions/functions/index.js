const functions = require('firebase-functions');
let FieldValue = require('firebase-admin').firestore.FieldValue;
let Timestamp = require('firebase-admin').firestore.Timestamp;
var admin = require('firebase-admin');
var stripe = require('stripe')('sk_test_YDfxhI8fNY9UAPbKX1wtITCQ', {
    apiVersion: '2020-03-02',
});

admin.initializeApp();
let db = admin.firestore();

exports.createStripeCustomer = functions.auth.user().onCreate(async (user) => {
    const customer = await stripe.customers.create({});
    return await admin.firestore().collection('users').doc(user.uid).set({
        created : FieldValue.serverTimestamp(),
        customer: customer.id
    });
});

exports.newMessage = functions.firestore.document('offers/{offer}/messages/{message}').onCreate(async (snap, context) => {
    try {
        const newMessage = snap.data();
        const offerID = snap.ref.parent.parent.id
        const parent = await snap.ref.parent.parent.get();
        const offerData = parent.data()
        if (offerData.seller === newMessage.sender) {
            notifyUser('New Message', newMessage.text, offerData.customer, 'message', offerID)
        } else {
            notifyUser('New Message', newMessage.text, offerData.seller, 'message', offerID)
        }
        return true
    } catch (error) {
        console.log(error)
        return true
    }
})

exports.newOffer = functions.firestore.document('offers/{offer}').onUpdate(async (change,context) => {
    try {
        const after = change.after.data();
        const before = change.before.data();
        if (after.hasOwnProperty('amount') && !before.hasOwnProperty('amount')) {
            notifyUser('💰 New Offer 💰', '$' + after.amount.toString() + ' for your ' + after.itemName, after.seller, 'message', context.params.offer)
            return true
        }
        if (after.hasOwnProperty('accepted') && !before.hasOwnProperty('accepted')) {
            notifyUser('🎉 Offer Accepted 🎉', 'Organize the sale in app for the ' + after.itemName, after.customer, 'message', context.params.offer)
            return true
        }
        if (after.hasOwnProperty('payment') && !before.hasOwnProperty('payment')) {
            notifyUser('💸 Customer Paid 💸', 'Time to ship or meet up with the customer for your ' + after.itemName, after.seller, 'message', context.params.offer)
            return true
        }
        if (after.hasOwnProperty('shipped') && !before.hasOwnProperty('shipped')) {
            notifyUser('📦 Item Shipped 📦', 'PrettyBoy & Co has shipped your ' + after.itemName + ', track and communicate within the app.', after.customer, 'message', context.params.offer)
            return true
        }
        if (after.complete) {
            notifyUser('👍 Sale Complete 👍', 'The customer has recieved and completed', after.seller, 'message', context.params.offer)
            notifyUser('👍 Purchase Complete 👍', 'Thanks for using the PrettyBoy & Co app!', after.customer, 'message', context.params.offer)
            return true
        }
    } catch (error) {
        console.log(error)
        return true
    }
})


exports.notifyAll = functions.firestore.document('notifications/{notification}').onCreate((snap, context) => {
    try {
        const data = snap.data()
        var payload = {
            notification: {
                title: data.title,
                body: data.message,
            },
            topic: 'allUsers'
        };

        admin.messaging().send(payload)
            .then((response) => {
            // Response is a message ID string.
                console.log('Successfully sent message:', response);
                return true
            })
            .catch((error) => {
                console.log('Error sending message:', error);
                return false
            });
        return true
    } catch (error) {
        console.log(error)
        return false
    }
}) 

exports.newItem = functions.firestore.document('items/{item}').onCreate((snap, context) => {
    try {
        const newItem = snap.data();
        const tags = newItem.tags;
        db.collectionGroup('tags').where('tags', 'array-contains-any',tags).get()
            .then(snapshot => {
                if (snapshot.empty) {
                    console.log('no tags found')
                    return
                }
                snapshot.forEach(doc => {
                    console.log(doc.ref)
                    notifyUser('🔌 ' + newItem.name + '🔌 ', 'Just posted for $' + newItem.cost.toString(), doc.ref.parent.parent.id, 'item', snap.id)
                    return 'tryied notifie'
                })
                return 'looped'
            })
            .catch(error => {
                console.log('Error getting documents', error);
            })
        return 'done'
    } catch (error) {
        console.log(error);
        return false
    }
});

function notifyUser(title, message, user, notificationKind, notificationID) {
    console.log('getting user' + user)
    db.collection('users').doc(user).get()
        .then(doc => {
            if (!doc.exists) {
                console.log('No such document!');
            } else {
                const data = doc.data()
                if (data.hasOwnProperty('token')) {
                    console.log('Document data:', doc.data());
                    var payload = {
                        notification: {
                            title: title,
                            body: message,
                        },
                        data: {
                            kind: notificationKind,
                            id: notificationID
                        }
                    };

                    admin.messaging().sendToDevice(data.token, payload)
                }
            }
            return 'notified'
        })
        .catch(err => {
            console.log('Error getting document', err);
        });
}


exports.purchaseItem = functions.https.onCall(async (data, context) => {
    try {
        const customer = await db.collection('users').doc(context.auth.uid).get()
        const offerRef = db.collection('offers').doc(data.offer)
        const offer = await offerRef.get()
        const cost = (parseInt(offer.data()['amount']) * 100)
        const intent = await stripe.paymentIntents.create({
            payment_method  : data.method,
            amount          : cost,
            confirm         : true,
            currency        : 'usd',
            customer        : customer.data()['customer'],
            metadata    : {
                offer   : data.offer,
                item    : data.item
            }
        })
        var updatedOffer = {}
        updatedOffer['payment'] = intent.id
        updatedOffer['modified'] = Timestamp.now()
        if ('shipping_name' in data) {
            updatedOffer['shipping_name'] = data.shipping_name
            updatedOffer['shipping_address'] = data.shipping_address 
        }
        await offerRef.update(updatedOffer)
        return intent.client_secret
    } catch (error) {
        console.log(error)
        return null
    } 
});

exports.getSingleCharge = functions.https.onCall(async (data, context) => {
    try {
        return await stripe.paymentIntents.retrieve(data.payment)
    } catch (error) {
        console.log(error)
        return error
    }
})

exports.listCustomerCharges = functions.https.onCall(async (data, context) => {
    try {
        const customer = await db.collection('users').doc(context.auth.uid).get()
        return await stripe.paymentIntents.list({
            customer: customer.data()['customer'],
            limit: 100,
            created: {
                gt: 1590775385
            }
        })
    } catch (error) {
        console.log(error)
        return error
    }
})

exports.ListAllCharges = functions.https.onCall(async (data, context) => {
    try {
        const result = await stripe.paymentIntents.list({   limit: 100,
            created: {
                gt: 1590775385
            }
        })
        return result
    } catch (error) {
        console.log(error)
        return error
    }
})