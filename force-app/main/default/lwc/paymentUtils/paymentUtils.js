export class authNet {

    generateOneTimePayload(obj) {
        let payment = {
            creditCard: {
                cardNumber: obj.CC.split('-').join(''),
                expirationDate: obj.Exp.split(' / ').reverse().join('-'),
                cardCode: obj.CVC
            }
        }
        let billTo = {
            firstName: obj.FirstName,
            lastName: obj.LastName,
            company: obj.Company,
            address: obj.Street,
            city: obj.City,
            state: obj.State,
            zip: obj.Zip,
            country: 'US',
            phoneNumber: obj.Phone
        }
        let customer = {
            type: 'individual',
            email: obj.Email
        }
        let auth = {
            name: obj.apiId,
            transactionKey: obj.apiKey
        }

        return {
            createTransactionRequest: {
                merchantAuthentication: auth,
                transactionRequest: {
                    transactionType: 'authCaptureTransaction',
                    amount: obj.detail.amount,
                    payment: payment,
                    customer: customer,
                    billTo: billTo,
                    authorizationIndicatorType: {
                        authorizationIndicator: 'final'
                    }
                }
            }
        }
    }

    generateRecurringPayload(obj) {
        let auth = {
            name: obj.apiId,
            transactionKey: obj.apiKey
        }
        let schedule = {
            interval: {
                length: obj.detail.recurringInterval.intervalCount,
                unit: obj.detail.recurringInterval.interval
            },
            startDate: obj.detail.recurringInterval.startDate,
            totalOccurrences: 9999
        }
        let payment = {
            creditCard: {
                cardNumber: obj.CC,
                expirationDate: obj.Exp,
                cardCode: obj.CVC
            }
        }
        let customer = {
            type: 'individual',
            email: obj.Email,
            phoneNumber: obj.Phone
        }
        let billTo = {
            firstName: obj.FirstName,
            lastName: obj.LastName,
            company: null,
            address: obj.Street,
            city: obj.City,
            state: obj.State,
            zip: obj.Zip,
            country: 'US'
        }

        return {
            ARBCreateSubscriptionRequest: {
                merchantAuthentication: auth,
                subscription: {
                    paymentSchedule: schedule,
                    amount: obj.detail.amount,
                    payment: payment,
                    customer: customer,
                    billTo: billTo
                }
            }
        }
    }

    async makeOneTimePayment(url, obj) {
        const callout = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Accept: '*/*',
                'Accept-Encoding': 'gzip, deflate, br'
            },
            body: JSON.stringify(obj)
        })
        const resp = await callout.json()
        if (resp.messages.resultCode === 'Error') {
            throw new Error(resp.transactionResponse.errors[0].errorText)
        }
        return resp
    }

    async makeRecurringPayment(url, obj) {
        const callout = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Accept: '*/*',
                'Accept-Encoding': 'gzip, deflate, br'
            },
            body: JSON.stringify(obj)
        })
        const resp = await callout.json()
        if (resp.messages.resultCode === 'Error') {
            throw new Error(resp.messages.message[0].text)
        }
        return resp
    }

}