/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CSG_LOGO from '@salesforce/resourceUrl/CSG_Logo';

import getInvoice from '@salesforce/apex/InvoicePaymentController.getInvoice';
export default class InvoicePayment extends LightningElement {
	csgLogo = CSG_LOGO;
	invoiceId;
	data;
	amount;
	showInvoice = true;
	lock = false;
	loading = true;
	saving = false;

	// # LIFECYCLE HOOKS

	connectedCallback() {
		this.invoiceId = 'a0qVG000000LXtpYAG'; // this.currentPageReference.state.c__invoice
		console.log(this.invoiceId);
	}

	// # APEX

	@wire(CurrentPageReference)
	currentPageReference;

	@wire(getInvoice, { id: '$invoiceId' })
	wiredInvoice({ error, data }) {
		if (data) {
			this.data = JSON.parse(JSON.stringify(data));
			this.data.lineItems = this.data.lineItems.map((e) => {
				e.formattedAmount = this.toUsdCurrency(e.amount);
				return e;
			});
			this.data.invoiceId = this.invoiceId;
			
			console.log('Data::', this.data);
			setTimeout(() => {
				this.loading = false;
			}, 1000);
		} else {
			console.log('Error::', error);
		}
	}

	// # PRIVATE METHODS

	showToast(title, msg, variant, mode = 'dismissible') {
		const event = new ShowToastEvent({
			title: title,
			message: msg,
			variant: variant,
			mode: mode,
		});
		this.dispatchEvent(event);
	}

	toUsdCurrency(amount) {
		const format = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });
		return format.format(amount);
	}

	// # HANDLERS

	clickPaymentDetailsBtn() {
		this.showInvoice = false;
	}

	clickPayBtn() {
		let processor = this.template.querySelector('c-payment-processor');
		processor.invoice = this.data;
		processor.sendPayment();
	}

	makePaymentCustomEvent(e) {
		this.lock = e.detail.lock;
	}

	// # GETTERS/SETTERS

	get isLoading() {
		return this.loading || this.saving;
	}

	get formattedAddress() {
		return this.data.billTo.city != null
			? this.data.billTo.city + ', ' + this.data.billTo.state + ' ' + this.data.billTo.zip
			: null;
	}

	get serviceFee() {
		this.data.serviceFee = this.data.amount * 0.04;
		return this.toUsdCurrency(this.data.serviceFee);
	}

	get total() {
		this.data.amount += this.data.serviceFee;
		return this.toUsdCurrency(this.data.amount);
	}
}
