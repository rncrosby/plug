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
        email   : user.email,
        customer: customer.id
    });
});

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