import { LightningElement, api, wire } from 'lwc';
// import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import getTextTemplate from '@salesforce/apex/EmailInvoicePDFController.getTextTemplate';
import sendInvoiceEmail from '@salesforce/apex/EmailInvoicePDFController.sendInvoiceEmail';

export default class EmailInvoicePDF extends NavigationMixin(LightningElement) {
	@api recordId;
	isLoading = true;
	isSent = false;
	error;

	invoice;
	template;

	subject;
	emailBody;
	emailRecipients;
	isFirstFormat = true;

	@wire(getTextTemplate, { recordId: '$recordId' })
	getWrapper({ error, data }) {
		if (data) {
			console.log(data);
			this.invoice = data.invoice;
			this.template = data.template;
			this.subject = 'CSG Invoice ' + data.invoice.Invoice_Number__c;
			this.emailBody = data.templateText;
			// console.log(this.emailBody);
			this.emailRecipients = data.invoice?.Contact__r?.Email;
			this.error = undefined;
			this.isLoading = false;
		} else if (error) {
			this.isLoading = false;
			this.error = error;
			console.error(error);
		}
	}

	// connectedCallback() {
	// 	this.isLoading = false;
	// }

	previewPDF() {
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__webPage',
			attributes: {
				url: '/apex/InvoicePDF?Id=' + this.recordId,
			},
		}).then((url) => {
			window.open(url, '_blank');
		});
	}

	// Send Email
	async handleSendEmail() {
		this.isLoading = true;
		await this.sendEmail();
		if (this.error) {
			return;
		}
		this.handleClose();
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Success',
				message: 'Invoice was successfully sent!',
				variant: 'success',
			})
		);
	}

	async sendEmail() {
		try {
			await sendInvoiceEmail({
				invoice: this.invoice,
				subject: this.subject,
				emailBody: this.emailBody,
			});

			this.isSent = true;
			this.isLoading = false;
		} catch (error) {
			this.error = error;
			console.error(error);
			this.isLoading = false;
		}
	}

	handleChangeBody(event) {
		const updatedText = event.target.value;
		if (this.isFirstFormat) {
			console.log(updatedText);
			updatedText.replaceAll('<p><br></p>', '');
			this.isFirstFormat = false;
			console.log(updatedText);
		}
		this.emailBody = updatedText;
		console.log(this.emailBody);
	}

	handleChangeSubject(event) {
		this.subject = event.target.value;
	}

	// Close Modal with output
	handleClose() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	get isEmailSent() {
		return this.isLoading || this.isSent;
	}
}