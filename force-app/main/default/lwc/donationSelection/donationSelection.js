import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getDonationAmounts from '@salesforce/apex/DonationSelectionController.getDonationAmounts';
import getProcessingFee from '@salesforce/apex/DonationSelectionController.getProcessingFee';

export default class DonationSelection extends LightningElement {
	@api headerColor;
	@api headerTextColor;
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

	// # LIFECYCLE HOOKS
	
	connectedCallback() {
		console.log('callback');
		this.getProcessingFee()
		this.getDonationAmounts()
	}

	renderedCallback() {
		if (this.changeAmt) {
			this.template.querySelectorAll('.typeBtn').forEach(i => {
				console.log(i);
				console.log(i.classList);
				if (i.classList.contains('slds-button_brand')) {
					this.unfocusBtn(i)			
				}
			})
	
			let typeBtn = this.template.querySelector('[data-id="' + this.givingType + '"]')
			console.log(typeBtn);
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
	}

	// # APEX

	@wire(CurrentPageReference)
	currentPageReference;

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
							console.log(currentAmount);
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
				hasHonor: this.honor,
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
		console.log(this.amtIndex);
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
			this.changeAmt = false;
			this.donationSelection = false;	
		}	
	}

	clickBackBtn() {
		this.donationSelection = true;
		this.changeAmt = true;
	}

	clickDonateBtn() {
		if (this.validate()) {

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

			this.givingInterval = {
				isRecurring: this.showFreq,
				interval: interval,
				intervalCount: count
			}

			console.log(this.givingInterval);

			console.log('send to payment processor');
		}
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
			{ label: 'Alabama', value: 'Alabama' },
			{ label: 'Alaska', value: 'Alaska' },
			{ label: 'Arizona', value: 'Arizona' },
			{ label: 'Arkansas', value: 'Arkansas' },
			{ label: 'California', value: 'California' },
			{ label: 'Colorado', value: 'Colorado' },
			{ label: 'Connecticut', value: 'Connecticut' },
			{ label: 'Delaware', value: 'Delaware' },
			{ label: 'Florida', value: 'Florida' },
			{ label: 'Georgia', value: 'Georgia' },
			{ label: 'Hawaii', value: 'Hawaii' },
			{ label: 'Idaho', value: 'Idaho' },
			{ label: 'Illinois', value: 'Illinois' },
			{ label: 'Indiana', value: 'Indiana' },
			{ label: 'Iowa', value: 'Iowa' },
			{ label: 'Kansas', value: 'Kansas' },
			{ label: 'Kentucky', value: 'Kentucky' },
			{ label: 'Louisiana', value: 'Louisiana' },
			{ label: 'Maine', value: 'Maine' },
			{ label: 'Maryland', value: 'Maryland' },
			{ label: 'Massachusetts', value: 'Massachusetts' },
			{ label: 'Michigan', value: 'Michigan' },
			{ label: 'Minnesota', value: 'Minnesota' },
			{ label: 'Mississippi', value: 'Mississippi' },
			{ label: 'Missouri', value: 'Missouri' },
			{ label: 'Montana', value: 'Montana' },
			{ label: 'Nebraska', value: 'Nebraska' },
			{ label: 'Nevada', value: 'Nevada' },
			{ label: 'New Hampshire', value: 'New Hampshire' },
			{ label: 'New Jersey', value: 'New Jersey' },
			{ label: 'New Mexico', value: 'New Mexico' },
			{ label: 'New York', value: 'New York' },
			{ label: 'North Carolina', value: 'North Carolina' },
			{ label: 'North Dakota', value: 'North Dakota' },
			{ label: 'Ohio', value: 'Ohio' },
			{ label: 'Oklahoma', value: 'Oklahoma' },
			{ label: 'Oregon', value: 'Oregon' },
			{ label: 'Pennsylvania', value: 'Pennsylvania' },
			{ label: 'Rhode Island', value: 'Rhode Island' },
			{ label: 'South Carolina', value: 'South Carolina' },
			{ label: 'South Dakota', value: 'South Dakota' },
			{ label: 'Tennessee', value: 'Tennessee' },
			{ label: 'Texas', value: 'Texas' },
			{ label: 'Utah', value: 'Utah' },
			{ label: 'Vermont', value: 'Vermont' },
			{ label: 'Virginia', value: 'Virginia' },
			{ label: 'Washington', value: 'Washington' },
			{ label: 'West Virginia', value: 'West Virginia' },
			{ label: 'Wisconsin', value: 'Wisconsin' },
			{ label: 'Wyoming', value: 'Wyoming' }
		]
	}

	get isHonor() {
		return this.honorSelection === 'honor'
	}

	get typeOnce() {
		console.log('test');
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
}