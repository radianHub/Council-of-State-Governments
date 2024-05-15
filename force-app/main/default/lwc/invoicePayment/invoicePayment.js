import { LightningElement, api, wire} from "lwc";
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getInvoice from '@salesforce/apex/InvoicePaymentController.getInvoice';
export default class InvoicePayment extends LightningElement {
	invoiceId
	lock = false
	loading = true
	saving = false

	// # LIFECYCLE HOOKS

	connectedCallback() {
		this.invoiceId = 'a0qVG000000LXtpYAG' // this.currentPageReference.state.c__invoice
		console.log(this.invoiceId);
		this.loading = true
	}

	// # APEX

	@wire(CurrentPageReference)
	currentPageReference

	@wire(getInvoice, { id: '$invoiceId' })
		wiredInvoice({ error, data }) {
			if (data) {
				console.log(data);
			} else {
				console.log(error);
			}
		}

	// # PRIVATE METHODS

	showToast(title, msg, variant, mode = 'dismissible') {
		const event = new ShowToastEvent({
				title: title,
				message: msg,
				variant: variant,
				mode: mode
		})
		this.dispatchEvent(event)
	}

	// # HANDLERS

	// # GETTERS/SETTERS

	get isLoading() {
		return (this.loading || this.saving)
	}
}