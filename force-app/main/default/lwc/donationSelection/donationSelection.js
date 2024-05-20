/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userId from '@salesforce/user/Id';

import getDonationAmounts from '@salesforce/apex/DonationSelectionController.getDonationAmounts';
import getProcessingFee from '@salesforce/apex/DonationSelectionController.getProcessingFee';
import getUserContact from '@salesforce/apex/DonationSelectionController.getUserContact';

export default class DonationSelection extends LightningElement {
	@api headerColor;
	@api headerTextColor;
	data;
	campaignId;
	processingFee;
	donationAmounts;	
	givingType;
	recurFreq;
	amtIndex;
	useOther = false;
	showFreq = false;
	honor = false;
	honorSelection;
	honoree = {};
	donationAmt = 0;
	addFee = false;
	changeAmt = false;
	donationSelection = true;

	lock = false;
	loading = true;
	saving = false;

	// # LIFECYCLE HOOKS
	
	connectedCallback() {
		this.campaignId = this.currentPageReference.state.c__campaign
		this.getProcessingFee()
		this.getDonationAmounts()
	}

	renderedCallback() {
		if (this.changeAmt) {
			this.template.querySelectorAll('.typeBtn').forEach(i => {
				if (i.classList.contains('slds-button_brand')) {
					this.unfocusBtn(i)			
				}
			})
	
			let typeBtn = this.template.querySelector('[data-id="' + this.givingType + '"]')
			this.focusBtn(typeBtn)
	
			if (this.showFreq) {
				this.template.querySelectorAll('.freqBtn').forEach(i => {
					if (i.classList.contains('slds-button_brand')) {
						this.unfocusBtn(i)
					}
				})
		
				let freqBtn = this.template.querySelector('[data-id="' + this.recurFreq + '"]')
				this.focusBtn(freqBtn)				
			}

			if(this.useOther) {
				this.template.querySelectorAll('.amtBtns').forEach(i => {
					if (i.classList.contains('slds-button_brand')) {
						this.unfocusBtn(i)
					}
				})

				this.template.querySelector('[data-id="otherAmt"]').value = this.donationAmt
			} else {
				this.template.querySelectorAll('.amtBtns').forEach(i => {
					if (i.classList.contains('slds-button_brand')) {
						this.unfocusBtn(i)
					}
				})
				
				let amtBtn = this.template.querySelector('[name="' + this.amtIndex + '"]')
				this.focusBtn(amtBtn)
			}
			this.changeAmt = false
		}

		setTimeout(() => {this.loading = false}, 1000)
	}

	// # APEX

	@wire(CurrentPageReference)
	currentPageReference;

	@wire(getUserContact, { id: '005VG0000053WzlYAE' }) // REPLACE WITH userId
	wiredContact({ data, error }) {
		if (data) {
			this.data = {
				campaignId: this.campaignId,
				contactId: data.Id,
				firstName: data.FirstName,
				lastName: data.LastName,
				company: data.Account.Name,
				phone: data.Phone,
				email: data.Email,
				street: data.MailingStreet,
				city: data.MailingCity,
				state: data.MailingState,
				zip: data.MailingPostalCode
			};

			this.data = JSON.parse(JSON.stringify(this.data))
		} else {
			console.log(error);
		}
	}

	getProcessingFee() {
		getProcessingFee()
			.then((r) => {this.processingFee = r;})
			.catch((e) => {console.log(e)})
	}

	getDonationAmounts() {
		getDonationAmounts()
			.then((r) => {
				this.donationAmounts = {
					month: null,
					once: null
				}
				r.forEach(e => {
					let amountArr = []
					if (e.Auto_Calculate__c) {
						let currentAmount = e.Starting_Amount__c.toFixed(2)
						for (let i = 0; i < 6; i++) {
							amountArr.push(currentAmount)
							currentAmount = Math.round(currentAmount * (1 + (e.Percentage_to_Auto_Calculate__c * 0.01))).toFixed(2)
						}
					} else {
						amountArr.push(
							e.Giving_Amount_1__c.toFixed(2),
							e.Giving_Amount_2__c.toFixed(2),
							e.Giving_Amount_3__c.toFixed(2),
							e.Giving_Amount_4__c.toFixed(2),
							e.Giving_Amount_5__c.toFixed(2),
							e.Giving_Amount_6__c.toFixed(2)
						)
					}
	
					if (e.DeveloperName === 'Recurring') {
						this.donationAmounts.month = amountArr
					} else if (e.DeveloperName === 'One_Time') {
						this.donationAmounts.once = amountArr
					}
				});
				this.givingType = 'once'
				this.recurFreq = 'month'
				console.log(this.donationAmounts)
			})
			.catch((e) => {
				console.log(e);
			})
	}

	// # PRIVATE METHODS

	showToast(title, msg, variant, mode = 'pester') {
		const event = new ShowToastEvent({
				title: title,
				message: msg,
				variant: variant,
				mode: mode
		})
		this.dispatchEvent(event);
	}

	unfocusBtn(btn) {
		btn.classList.remove('slds-button_brand')
		btn.classList.add('slds-button_neutral')
	}

	focusBtn(btn) {
		btn.classList.remove('slds-button_neutral')
		btn.classList.add('slds-button_brand')
	}

	validate() {
		const validLI = [...this.template.querySelectorAll('.honorInfo lightning-input')]
		.reduce((isValid, inp) => {
			inp.reportValidity()
			let valid = inp.checkValidity()

			return isValid && valid
		}, true)

		const validLCB = [...this.template.querySelectorAll('.honorInfo lightning-combobox')]
		.reduce((isValid, inp) => {
			inp.reportValidity()
			let valid = inp.checkValidity()

			return isValid && valid
		}, true)	
	
		if (validLI && validLCB) {
			const li = [...this.template.querySelectorAll('.honorInfo lightning-input')]
			.forEach(e => {
				this.honoree[e.name] = e.value
			})
			const lcb = [...this.template.querySelectorAll('.honorInfo lightning-combobox')]
			.forEach(e => {
				this.honoree[e.name] = e.value
			})

			this.honoree = {
				...this.honoree,
				honorType: this.honorSelection
			}
		}

		return validLI && validLCB
	}

	// # HANDLERS

	clickHonorCheckBox(e) {
		this.honor = e.detail.checked
		if (this.honor) {
			this.honorSelection = 'honor'
		}
	}

	honorGroupChanged(e) {
		this.honorSelection = e.detail.value
	}

	clickDonationTypeBtn(e) {
		this.donationAmt = 0
		this.template.querySelectorAll('.typeBtn').forEach(i => {
			if (i.classList.contains('slds-button_brand')) {
				this.unfocusBtn(i)			
			}
		});

		let btn = this.template.querySelector('[data-id="' + e.currentTarget.dataset.id + '"]')
		this.focusBtn(btn)
		
		this.givingType = e.currentTarget.value;
		this.showFreq = this.givingType === 'recur' ? true : false
	}

	clickFreqTypeBtn(e) {
		this.template.querySelectorAll('.freqBtn').forEach(i => {
			if (i.classList.contains('slds-button_brand')) {
				this.unfocusBtn(i)
			}
		})

		let btn = this.template.querySelector('[data-id="' + e.currentTarget.dataset.id + '"]')
		this.focusBtn(btn)

		this.recurFreq = e.currentTarget.value;
	}

	clickDonationAmtBtn(e) {
		let otherAmt = this.template.querySelector('[data-id="otherAmt"]')
		otherAmt.value = null
		this.useOther = false;

		this.template.querySelectorAll('.amtBtns').forEach(i => {
			if (i.classList.contains('slds-button_brand')) {
				this.unfocusBtn(i)
			}
		})
		
		let btn = this.template.querySelector('[name="' + e.currentTarget.name + '"]')
		this.focusBtn(btn)

		this.donationAmt = e.currentTarget.value
		this.amtIndex = e.currentTarget.name
	}

	changeOtherDonationAmt(e) {
		this.template.querySelectorAll('.amtBtns').forEach(i => {
			if (i.classList.contains('slds-button_brand')) {
				this.unfocusBtn(i)
			}
		})

		this.donationAmt = e.detail.value
		this.useOther = true;
	}

	checkFeeCheckbox(e) {
		this.addFee = e.currentTarget.checked
	}

	clickPaymentDetailsBtn() {
		if (this.donationAmt === 0) {
			this.showToast('Error', 'You must select or provide an other amount.', 'error')
		} else if (!this.validate()) {
			this.showToast('Error', 'You must provide the required information.', 'error')
		} else if (this.validate) {
			let interval
			let count;
			if (this.showFreq) {
				switch (this.recurFreq) {
					case 'week':
						interval = 'days'
						count = 7
						break
					case 'biweek':
						interval = 'days'
						count = 14
						break
					case 'month':
						interval = 'months'
						count = 1
						break
					case 'quarter':
						interval = 'months'
						count = 3
						break
					case 'year':
						interval = 'months'
						count = 12
						break
					default:
						interval = 'once'
						count = 1
						break
				}	
			} else {
				interval = 'once'
				count = 1
			}

			let givingInterval = {
				startDate: new Date().toJSON().slice(0, 10),
				interval: interval,
				intervalCount: count
			}

			this.data = {
				...this.data,
				isRecurring: this.showFreq,
				recurringInterval: givingInterval,
				isHonoree: this.honor,
				honoree: this.honoree,
				amount: Number(this.total)
			}

			console.log('DATA::', this.data);

			this.changeAmt = false;
			this.donationSelection = false;
		}	
	}

	clickBackBtn() {
		this.donationSelection = true;
		this.changeAmt = true;
	}

	clickDonateBtn() {
		console.log('Donate');
		if (this.validate()) {
			let processor = this.template.querySelector('c-payment-processor')
			processor.sendPayment()
		}
	}

	makePaymentCustomEvent(e) {
		this.lock = e.detail.lock
	}

	// # GETTERS/SETTERS

	get honorOptions() {
		return [
			{ label: 'Honor', value: 'honor' },
			{ label: 'Memorial', value: 'memorial' }
		]
	}

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
			{ label: 'WY', value: 'WY' }
		]
	}

	get isHonor() {
		return this.honorSelection === 'honor'
	}

	get typeOnce() {
		return this.givingType === 'once'
	}

	get typeRecur() {
		return this.givingType === 'recur'
	}
	
	get fee() {
		return this.processingFee.Use_Flat_Fee__c 
			? ((Number(this.processingFee.Flat_Fee__c)).toFixed(2)).toString()
			: ((Number(this.donationAmt) * (Number(this.processingFee.Processing_Fee_Percentage__c) * 0.01)).toFixed(2)).toString()
	}

	get total() {
		return this.addFee 
			? (Number(this.donationAmt) + Number(this.fee)).toFixed(2).toString()
			: Number(this.donationAmt).toString() + '.00'
	}

	get noTotal() {
		return Number(this.total) !== 0;
	}

	get feeCheckboxLabel() {
		return 'I would like to cover the processing fee by adding $' + this.fee + ' to my donation.'
	}

	get selectedDonation() {
		return this.donationAmt !== 0
	}

	get customTextColor() {
		return 'color:' + this.headerTextColor + ';font-size:x-large;'
	}

	get customHeaderColor() {
		return 'background-color:' + this.headerColor + ';'
	}

	get isLoading() {
		return (this.loading || this.saving)
	}

}