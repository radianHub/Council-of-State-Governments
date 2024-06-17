@isTest
private class EmailInvoicePDFControllerTest {
	@isTest
	static void checkForTemplate() {
		String templateName = EmailInvoicePDFController.TEMPLATE_NAME;
		CustomTemplate__mdt template = CustomTemplate__mdt.getInstance(templateName);

		Assert.isNotNull(template, 'Template MDT not found for: ' + templateName);
		Assert.isTrue(template.Text__c.length() > 0, 'Template Text is empty for: ' + templateName);
	}

	@IsTest
	static void getTextTemplateTest() {
		Invoice__c invoice = (Invoice__c) new SObjectBuilder(Invoice__c.sObjectType)
			.put(Invoice__c.Due_Date__c, Date.today())
			.create()
			.getRecord();

		Test.startTest();
		EmailInvoicePDFController.TemplateWrapper wrapper = EmailInvoicePDFController.getTextTemplate(invoice.Id);
		Test.stopTest();

		Assert.areEqual(invoice.Id, wrapper.invoice.Id, 'Invoice Ids should match');
		Assert.isNotNull(wrapper.template, 'Template should not be null');
		Assert.isFalse(wrapper?.templateText.contains('{!'), 'All template tags should\'ve been replaced');
	}

	@isTest
	static void sendInvoiceEmailTest() {
		Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
			.put(Contact.Email, 'test@email.com.invalid')
			.create()
			.getRecord();
		Invoice__c invoice = (Invoice__c) new SObjectBuilder(Invoice__c.sObjectType)
			.put(Invoice__c.Due_Date__c, Date.today())
			.put(Invoice__c.Contact__c, contact.Id)
			.create()
			.getRecord();

		Boolean emailSuccess = false;
		Test.startTest();
		emailSuccess = EmailInvoicePDFController.sendInvoiceEmail(invoice, 'Email Subject', 'My Email Body');
		Test.stopTest();

		Assert.isTrue(emailSuccess, 'Expected successful email send');
	}

	// # ERROR TESTS
	@isTest
	static void getTextTemplateTest_Errors() {
		// SObject junkRecord = new SObjectBuilder(Account.sObjectType).create().getRecord();
		Boolean errorInvoiceNull = false;
		Boolean errorIdMismatch = false;
		Boolean errorTemplateNotFound = false;
		try {
			EmailInvoicePDFController.TemplateWrapper wrapper = EmailInvoicePDFController.getTextTemplate(
				(Id) SObjectFactory.provideDummyId(Invoice__c.sObjectType).getValue()
			);
		} catch (Exception e1) {
			errorInvoiceNull = true;
		}
		Assert.isTrue(errorInvoiceNull, 'Expected an error from no Invoice found');

		try {
			EmailInvoicePDFController.TemplateWrapper wrapper = EmailInvoicePDFController.getTextTemplate(
				(Id) SObjectFactory.provideDummyId(Account.sObjectType).getValue()
			);
		} catch (Exception e2) {
			errorIdMismatch = true;
		}
		Assert.isTrue(errorIdMismatch, 'Expected an error from Id of incorrect type');

		// try {
		// 	EmailInvoicePDFController.TemplateWrapper wrapper = EmailInvoicePDFController.getTextTemplate(
		// 		SObjectFactory.provideDummyId(Account.sObjectType)
		// 	);
		// } catch (Exception e3) {
		// 	errorTemplateNotFound = true;
		// }
		// Assert.isTrue(errorTemplateNotFound, 'Expected an error from Text MDT not found');
	}

	// # HELPERS
	// private static Invoice__c createInvoice() {
	// 	Invoice__c invoice = (Invoice__c) new SObjectBuilder(Invoice__c.sObjectType)
	// 		.put(Invoice__c.Due_Date__c, Date.today())
	// 		.create()
	// 		.getRecord();
	// 	return invoice;
	// }
}