/* eslint-disable @lwc/lwc/no-async-operation */
// TODO: Build payment class
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { authNet } from 'c/paymentUtils';

import getSettings from '@salesforce/apex/PaymentProcessorController.getSettings';
import successfulPayment from '@salesforce/apex/PaymentProcessorController.successfulPayment';
export default class PaymentProcessor extends LightningElement {
	@api paymentType;
	@api invoice;
	@api donation;
	settings;
	data = {};
	authNet = new authNet();
	cc;
	paymentLock = false;
	loading = true;
	saving = false;

	// # LIFECYCLE HOOKS

    connectedCallback() {
        this.data.detail = this.paymentType === 'donation' ? this.donation : this.invoice;

        this.loading = false;
    }
    
	// # APEX
    
	@wire(getSettings)
	wiredSettings({ data, error }) {
        if (data) {
			this.data.apiId = data.API_Login_Id__c;
			this.data.apiKey = data.API_Key__c;
			this.data.url = data.Test_Mode__c ? data.Sandbox_Endpoint__c : data.Production_Endpoint__c;
		} else {
			console.log(error);
		}
	}

	successfulPayment(processor, json, isDonation) {
		successfulPayment({ processor: processor, jsonData: json, isDonation: isDonation })
			.then((r) => console.log(r))
			.catch((e) => console.log(e))
	}

	// TODO: Configure multiple Payment Processors. Pulled from custom setting or metadata

	// # PRIVATE METHODS

	validate() {
		const validLI = [...this.template.querySelectorAll('lightning-input')].reduce((isValid, inp) => {
			inp.reportValidity();
			let valid = inp.checkValidity();

			return isValid && valid;
		}, true);

		const validLCB = [...this.template.querySelectorAll('lightning-combobox')].reduce((isValid, inp) => {
			inp.reportValidity();
			let valid = inp.checkValidity();

			return isValid && valid;
		}, true);

		return validLI && validLCB;
	}

	showToast(title, msg, variant, mode = 'dismissible') {
		const event = new ShowToastEvent({
			title: title,
			message: msg,
			variant: variant,
			mode: mode,
		});
		this.dispatchEvent(event);
	}

	// # HANDLERS

	changeDataInput(e) {
		if (e.currentTarget.name === 'exp' && e.currentTarget.value.length === 2 && e.currentTarget.value[1] !== '/') {
			e.currentTarget.value += ' / ';
		}
		
		if (e.currentTarget.name === 'exp' || e.currentTarget.name === 'cvc' || e.currentTarget.name === 'cc') {
			this.data[e.currentTarget.name] = e.currentTarget.value;
		} else {
			this.data.detail = JSON.parse(JSON.stringify(this.data.detail))
			this.data.detail[e.currentTarget.name] = e.currentTarget.value
		}
	}

	focusOutCCInput(e) {
		e.currentTarget.maxLength = '20';
		if (e.currentTarget.value) {
			this.cc = e.currentTarget.value;
			let str = '';
			let arr = e.currentTarget.value.split('');
			for (let i = 0; i < arr.length; i++) {
				str += !i || i % 4 ? arr[i] : '-' + arr[i];
			}
			e.currentTarget.value = str;
		}
	}

	focusInCCInput(e) {
		e.currentTarget.maxLength = '16';
		if (this.cc) {
			e.currentTarget.value = this.cc;
		}
	}

	@api sendPayment() {
		if (this.validate()) {
			this.paymentLock = true;
			this.saving = true;

			let event = new CustomEvent('makepayment', {
				detail: {
					lock: true,
				},
			});
			this.dispatchEvent(event);

			if (this.paymentType === 'donation') {
				// * RECURRING PAYMENT
				if (this.data.detail.isRecurring) {
					console.log('handle recurring');
					let payload = this.authNet.generateRecurringPayload(this.data);
					this.authNet
						.makeRecurringPayment(this.data.url, payload)
						.then((r) => {
							let chargeDate = new Date();
							chargeDate.setDate(chargeDate.getDate() + 1);
							this.showToast(
								'Success',
								`Recurring payment saved, you will be charged at 2 AM PST ${chargeDate.toLocaleDateString()}`,
								'success',
								'sticky'
							);
							setTimeout(() => {
								this.saving = false;
							}, 1000);

							this.data.cc = '************' + this.data.cc.slice(-4);
							this.data = {
								...this.data,
								customerProfileId: r.profile.customerProfileId,
								paymentProfileId: r.profile.customerPaymentProfileId,
								subscriptionId: r.subscriptionId,
							};

							const { cvc, apiId, apiKey, url, ...rest } = this.data;
							console.log(rest);

							// TODO: SEND REST TO APEX CONTROLLER
						})
						.catch((e) => {
							this.showToast('Error', e.message, 'error');
							setTimeout(() => {
								this.paymentLock = false;
								this.saving = false;

								event = new CustomEvent('makepayment', {
									detail: {
										lock: false,
									},
								});
								this.dispatchEvent(event);
							}, 1000);
						});

					// * ONE TIME PAYMENT
				} else {
					console.log('handle one-time payment');
					let payload = this.authNet.generateOneTimePayload(this.data);
					this.authNet
						.makeOneTimePayment(this.data.url, payload)
						.then((r) => {
							this.showToast(
								'Success',
								'Your payment has been accepted, thank you for your donation!',
								'success',
								'sticky'
							);
							setTimeout(() => {
								this.saving = false;
							}, 1000);

							this.data.cc = '************' + this.data.cc.slice(-4);
							this.data = {
								...this.data,
								transId: r.transactionResponse.transId,
								networkTransId: r.transactionResponse.networkTransId,
								addressVerification: r.transactionResponse.avsResultCode,
								cvvVerification: r.transactionResponse.cvvResultCode,
							};

							const { cvc, apiId, apiKey, url, ...rest } = this.data;
							console.log(JSON.parse(JSON.stringify(rest)));

							this.successfulPayment(
								'Auth.net',	
								JSON.stringify(rest),
                                true
							);
						})
						.catch((e) => {
							this.showToast('Error', e.message, 'error');
							setTimeout(() => {
								this.paymentLock = false;
								this.saving = false;

								event = new CustomEvent('makepayment', {
									detail: {
										lock: false,
									},
								});
								this.dispatchEvent(event);
							}, 1000);
						});
				}

				// * INVOICE PAYMENT
			} else {
				this.data = {
					...this.data,
					company: this.data.detail.name,
					street: this.data.detail.billTo.street,
					city: this.data.detail.billTo.city,
					state: this.data.detail.billTo.state,
					zip: this.data.detail.billTo.zip,
					phone: this.data.detail.phone,
					email: this.data.detail.email,
				};

				let payload = this.authNet.generateOneTimePayload(this.data);
				this.authNet
					.makeOneTimePayment(this.data.url, payload)
					.then((r) => {
						this.showToast('Success', 'Your payment has been accepted, thank you!', 'success', 'sticky');
						setTimeout(() => {
							this.saving = false;
						}, 1000);

						this.data.cc = '************' + this.data.cc.slice(-4);
						this.data = {
							...this.data,
							transId: r.transactionResponse.transId,
							networkTransId: r.transactionResponse.networkTransId,
							addressVerification: r.transactionResponse.avsResultCode,
							cvvVerification: r.transactionResponse.cvvResultCode,
						};

						console.log(JSON.parse(JSON.stringify(this.data)));
						const { cvc, apiId, apiKey, url, ...rest } = this.data;

						this.successfulPayment(
							'Auth.net',
							JSON.stringify(rest),
                            false
						);
					})
					.catch((e) => {
						this.showToast('Error', e.message, 'error');
						setTimeout(() => {
							this.paymentLock = false;
							this.saving = false;

							event = new CustomEvent('makepayment', {
								detail: {
									lock: false,
								},
							});
							this.dispatchEvent(event);
						}, 1000);
					});
			}
		} else {
			this.showToast('Error', 'Please fill out the required information.', 'error');
		}
	}

	// # GETTERS/SETTERS

	get stateOptions() {
		return [
			{ label: 'AL', value: 'AL' },
			{ label: 'AK', value: 'AK' },
			{ label: 'AZ', value: 'AZ' },
			{ label: 'AR', value: 'AR' },
			{ label: 'CA', value: 'CA' },
			{ label: 'CO', value: 'CO' },
			{ label: 'CT', value: 'CT' },
			{ label: 'DE', value: 'DE' },
			{ label: 'FL', value: 'FL' },
			{ label: 'GA', value: 'GA' },
			{ label: 'HI', value: 'HI' },
			{ label: 'ID', value: 'ID' },
			{ label: 'IL', value: 'IL' },
			{ label: 'IN', value: 'IN' },
			{ label: 'IA', value: 'IA' },
			{ label: 'KS', value: 'KS' },
			{ label: 'KY', value: 'KY' },
			{ label: 'LA', value: 'LA' },
			{ label: 'ME', value: 'ME' },
			{ label: 'MD', value: 'MD' },
			{ label: 'MA', value: 'MA' },
			{ label: 'MI', value: 'MI' },
			{ label: 'MN', value: 'MN' },
			{ label: 'MS', value: 'MS' },
			{ label: 'MO', value: 'MO' },
			{ label: 'MT', value: 'MT' },
			{ label: 'NE', value: 'NE' },
			{ label: 'NV', value: 'NV' },
			{ label: 'NH', value: 'NH' },
			{ label: 'NJ', value: 'NJ' },
			{ label: 'NM', value: 'NM' },
			{ label: 'NY', value: 'NY' },
			{ label: 'NC', value: 'NC' },
			{ label: 'ND', value: 'ND' },
			{ label: 'OH', value: 'OH' },
			{ label: 'OK', value: 'OK' },
			{ label: 'OR', value: 'OR' },
			{ label: 'PA', value: 'PA' },
			{ label: 'RI', value: 'RI' },
			{ label: 'SC', value: 'SC' },
			{ label: 'SD', value: 'SD' },
			{ label: 'TN', value: 'TN' },
			{ label: 'TX', value: 'TX' },
			{ label: 'UT', value: 'UT' },
			{ label: 'VT', value: 'VT' },
			{ label: 'VI', value: 'VI' },
			{ label: 'WA', value: 'WA' },
			{ label: 'WV', value: 'WV' },
			{ label: 'WI', value: 'WI' },
			{ label: 'WY', value: 'WY' },
		];
	}

	get isLoading() {
		return this.loading || this.saving;
	}

	get isDonation() {
		return this.paymentType === 'donation';
	}
}
