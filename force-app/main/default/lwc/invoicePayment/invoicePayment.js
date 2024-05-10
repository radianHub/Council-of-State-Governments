import { LightningElement, api } from "lwc";
export default class InvoicePayment extends LightningElement {
	@api recordId;
	@api objectApiName;
}