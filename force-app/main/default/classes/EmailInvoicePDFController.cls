public with sharing class EmailInvoicePDFController {
	@TestVisible
	private final static String TEMPLATE_NAME = 'Invoice';

	@AuraEnabled(cacheable=true)
	public static TemplateWrapper getTextTemplate(Id recordId) {
		TemplateWrapper wrapper = new TemplateWrapper();
		try {
			Invoice__c invoice;
			List<Invoice__c> invoices = [
				SELECT Id, Name, Contact__c, Contact__r.Name, Contact__r.Email, Invoice_Number__c, Due_Date__c
				FROM Invoice__c
				WHERE Id = :recordId
			];
			if (invoices.size() == 0) {
				throw new AuraHandledException('No Invoice record found for Id: ' + recordId);
			}
			invoice = invoices[0];
			wrapper.invoice = invoice;

			// CustomTemplate__mdt template = CustomTemplate__mdt.getInstance(TEMPLATE_NAME);
			CustomTemplate__mdt template = [
				SELECT Id, MasterLabel, DeveloperName, Text__c
				FROM CustomTemplate__mdt
				WHERE DeveloperName = :TEMPLATE_NAME
			][0];

			if (template == null) {
				throw new AuraHandledException('No CustomTemplate MDT found for Name: ' + TEMPLATE_NAME);
			}
			wrapper.template = template;

			wrapper.templateText = replaceTags(invoice, template.Text__c);

			System.debug('Before returning wrapper');
			System.debug(wrapper);
			System.debug(wrapper.templateText);
			return wrapper;
		} catch (Exception e) {
			throw new AuraHandledException('Unknown error: ' + e.getMessage() + '~ Line:' + e.getLineNumber());
		}
	}
	@AuraEnabled
	public static Boolean sendInvoiceEmail(Invoice__c invoice, String subject, String emailBody) {
		try {
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			System.debug(invoice);
			email.setUseSignature(false);
			email.setSaveAsActivity(true);
			email.setSubject(subject);
			email.setHtmlBody(emailBody);

			email.setTargetObjectId(invoice.Contact__c);
			email.setWhatId(invoice.Id);

			List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
			attachments.add(getInvoicePDF(invoice.Id, invoice.Invoice_Number__c));
			attachments.add(getW9PDF());

			email.setFileAttachments(attachments);

			List<Messaging.SendEmailResult> emailResult = Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ email }
			);

			if (!emailResult[0].isSuccess()) {
				throw new AuraHandledException('Email failed to send.');
			}

			Invoice__c updateInvoice = new Invoice__c();
			updateInvoice.Id = invoice.Id;
			updateInvoice.LastInvoiceSentDT__c = Datetime.now();

			update updateInvoice;

			return true;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	// # PRIVATE METHODS

	// # TEMPLATE HELPERS
	private static String replaceTags(Invoice__c invoice, String text) {
		System.debug('In replaceTags');
		text = text.replace('{!Invoice__c.Invoice_Number__c}', invoice.Invoice_Number__c);
		text = text.replace('{!Contact.Name}', invoice.Contact__r.Name);
		text = text.replace('{!Invoice__c.Due_Date__c}', invoice.Due_Date__c.format());
		text = text.replace('{!User.Name}', UserInfo.getName());

		System.debug(text);
		return text;
	}

	// # INVOICE HELPERS
	private static Messaging.EmailFileAttachment getInvoicePDF(Id refId, String invoiceNumber) {
		System.debug('in getInvoicePDF');
		PageReference PDF = Page.InvoicePDF;
		PDF.getParameters().put('Id', refId);
		PDF.setRedirect(true);

		Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
		fileAttachment.setFileName('CSG Invoice ' + invoiceNumber + '.pdf');
		if (Test.isRunningTest()) {
			// if Test is running, cannot use .getContent from PageReference
			fileAttachment.setBody(Blob.valueOf('Test PDF Content'));
		} else {
			fileAttachment.setBody(PDF.getContent());
		}

		return fileAttachment;
	}

	private static Messaging.EmailFileAttachment getW9PDF() {
		System.debug('in getW9PDF');
		StaticResource sr = [SELECT Name, Id, Body FROM StaticResource WHERE Name = 'CSG_W9_PDF'];
		System.debug(sr);

		Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
		fileAttachment.setFileName('CSG W-9.pdf');
		fileAttachment.setBody(sr.Body);

		return fileAttachment;
	}

	public class TemplateWrapper {
		@AuraEnabled
		public Invoice__c invoice { get; set; }
		@AuraEnabled
		public CustomTemplate__mdt template { get; set; }
		@AuraEnabled
		public String templateText { get; set; }
	}
}