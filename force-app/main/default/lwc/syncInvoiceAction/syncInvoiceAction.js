import { LightningElement, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import sendInvoiceToSage from '@salesforce/apex/SyncInvoiceActionHandler.sendInvoiceToSage';
import sendPaymentToSage from '@salesforce/apex/SyncInvoiceActionHandler.sendPaymentToSage';

export default class SyncInvoiceAction extends LightningElement {
	_recordId;
    @api objectApiName;

    @api get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

	@api invoke() {
        console.log(this.objectApiName);

        if (this.objectApiName === 'Invoice__c') {
            sendInvoiceToSage({ id: this.recordId })
            .then((r) => {
                if (r) {
                    this.showToast('Success', 'Invoice synced successfully', 'success')
                }
            })
            .catch(error => {
                this.showToast('Error syncing invoice', error.body.message, 'error');
            }) 
        } else {
            sendPaymentToSage({ id: this.recordId })
            .then((r) => {
                if (r) {
                    this.showToast('Success', 'Payment synced successfully', 'success');
                }
            })
            .catch(error => {
                this.showToast('Error syncing payment', error.body.message, 'error');
            })
        }
	}

    showToast(title, msg, variant, mode = 'dismissible') {
        const event = new ShowToastEvent({
                title: title,
                message: msg,
                variant: variant,
                mode: mode
        })
        this.dispatchEvent(event)
    }

}