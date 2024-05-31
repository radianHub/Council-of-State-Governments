@isTest
public with sharing class SageIntegrationServiceTest {

    static final Map<String, HttpResponse> resStore = new Map<String, HttpResponse>{
        'postSuccess' => HttpResponseFactory.postSuccess(),
        'postFailure' => HttpResponseFactory.postFailure(),
        'getSuccess' => HttpResponseFactory.getSuccess(),
        'getFailure' => HttpResponseFactory.getFailure()
    };

    static final List<HttpMatchingStrategy> matchers = new List<HttpMatchingStrategy>{
        new HttpResponseMatchers.PostMatcher(),
        new HttpResponseMatchers.GetMatcher()
    };

    @isTest
    static void postProjectSuccess() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            true
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Follow Up',
            CloseDate = Date.today(),
            Description = 'This is a test',
            Active__c = true,
            ProjectStatus__c = 'Active',
            ProjectType__c = 'Other Restricted',
            ProjectCategory__c = 'Internal Non-billable',
            Location__c = 'NATL',
            Department__c = 'ADM',
            Restrictions__c = '10008',
            Start_Date__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id
        );
        insert opp;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();
    }

    @isTest
    static void postProjectFailure() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            false
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Follow Up',
            CloseDate = Date.today(),
            Description = 'This is a test',
            Active__c = true,
            ProjectStatus__c = 'Active',
            ProjectType__c = 'Other Restricted',
            ProjectCategory__c = 'Internal Non-billable',
            Location__c = 'NATL',
            Department__c = 'ADM',
            Restrictions__c = '10008',
            Start_Date__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id
        );
        insert opp;

        try {
            Test.startTest();
            opp.StageName = 'Closed Won';
            update opp; 
            Test.stopTest();
        }
        catch (CalloutException ex) {
            System.debug(ex.getMessage());
            Assert.isNotNull(ex.getMessage(), 'An exception was not thrown.');
        }
    }

    @isTest
    static void getProjectSuccess() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            true
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        SageIntegrationService.getProjects();
        Test.stopTest();
    }

    @isTest
    static void getProjectFailure() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            false
        );
        Test.setMock(HttpCalloutMock.class, mock);

        try {
            Test.startTest();
            SageIntegrationService.getProjects();
            Test.stopTest();
        }
        catch (CalloutException ex) {
            System.debug(ex.getMessage());
            Assert.isNotNull(ex.getMessage(), 'An exception was not thrown.');
        } 
    }

    @isTest
    static void postInvoiceSuccess() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            true
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Inntact_GL_Account__c glAcc = new Inntact_GL_Account__c(
            Name = 'Dues',
            Account_Id__c = '40010'
        );
        insert glAcc;
        
        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Follow Up',
            CloseDate = Date.today(),
            Description = 'This is a test',
            Active__c = true,
            ProjectStatus__c = 'Active',
            ProjectType__c = 'Other Restricted',
            ProjectCategory__c = 'Internal Non-billable',
            Location__c = 'NATL',
            Department__c = 'ADM',
            Restrictions__c = '10008',
            Start_Date__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id
        );
        insert opp;

        Invoice__c inv = new Invoice__c(
            Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Restrictions__c = '10008',
            Customer__c = acc.Id
        );
        insert inv;

        Invoice_Entry__c ie = new Invoice_Entry__c(
            Amount__c = 1000.45,
            GL_Account__c = glAcc.Id,
            Project__c = opp.Id,
            Invoice__c = inv.Id
        );
        insert ie;

        Test.startTest();
        Assert.isTrue(SyncInvoiceActionHandler.sendInvoiceToSage(inv.Id), 'The callout was not successful.');
        Test.stopTest();
    }

    @isTest
    static void postInvoiceNoLineItemFailure() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            false
        );
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Invoice__c inv = new Invoice__c(
            Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Restrictions__c = '10008',
            Customer__c = acc.Id
        );
        insert inv;

        Boolean success;
        try {
            Test.startTest();
            success = SyncInvoiceActionHandler.sendInvoiceToSage(inv.Id);
            Test.stopTest();
        }
        catch (Exception ex) {
            Assert.isNotNull(ex.getMessage(), 'Invoice synced successfully without Line Items');
        }
    }

    @isTest
    static void postInvoiceFailure() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            false
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Inntact_GL_Account__c glAcc = new Inntact_GL_Account__c(
            Name = 'Dues',
            Account_Id__c = '40010'
        );
        insert glAcc;
        
        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Follow Up',
            CloseDate = Date.today(),
            Description = 'This is a test',
            Active__c = true,
            ProjectStatus__c = 'Active',
            ProjectType__c = 'Other Restricted',
            ProjectCategory__c = 'Internal Non-billable',
            Location__c = 'NATL',
            Department__c = 'ADM',
            Restrictions__c = '10008',
            Start_Date__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id
        );
        insert opp;

        Invoice__c inv = new Invoice__c(
            Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Restrictions__c = '10008',
            Customer__c = acc.Id
        );
        insert inv;

        Invoice_Entry__c ie = new Invoice_Entry__c(
            Amount__c = 1000.45,
            GL_Account__c = glAcc.Id,
            Project__c = opp.Id,
            Invoice__c = inv.Id
        );
        insert ie;

        Boolean success;
        try {
            Test.startTest();
            success = SyncInvoiceActionHandler.sendInvoiceToSage(inv.Id);
            Test.stopTest();
        }
        catch (Exception ex) {
            Assert.isNotNull(ex.getMessage(), 'Invoice synced successfully with a bad request.');
        }
    }

    @isTest
    static void getInvoiceSuccess() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            true
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        SageIntegrationService.getInvoices();
        Test.stopTest();
    }

    @isTest
    static void getInvoiceFailure() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            false
        );
        Test.setMock(HttpCalloutMock.class, mock);

        try {
            Test.startTest();
            SageIntegrationService.getInvoices();
            Test.stopTest();
        }
        catch (CalloutException ex) {
            System.debug(ex.getMessage());
            Assert.isNotNull(ex.getMessage(), 'An exception was not thrown.');
        } 
    } 

    @isTest
    static void postPaymentSuccess() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            true
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Inntact_GL_Account__c glAcc = new Inntact_GL_Account__c(
            Name = 'Dues',
            Account_Id__c = '40010'
        );
        insert glAcc;
        
        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Follow Up',
            CloseDate = Date.today(),
            Description = 'This is a test',
            Active__c = true,
            ProjectStatus__c = 'Active',
            ProjectType__c = 'Other Restricted',
            ProjectCategory__c = 'Internal Non-billable',
            Location__c = 'NATL',
            Department__c = 'ADM',
            Restrictions__c = '10008',
            Start_Date__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id
        );
        insert opp;

        Invoice__c inv = new Invoice__c(
            Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Restrictions__c = '10008',
            Customer__c = acc.Id,
            State__c = 'Posted'
        );
        insert inv;

        Invoice_Entry__c ie = new Invoice_Entry__c(
            Amount__c = 1000.45,
            GL_Account__c = glAcc.Id,
            Project__c = opp.Id,
            Invoice__c = inv.Id
        );
        insert ie;

        Invoice_Payment__c pay = new Invoice_Payment__c(
            Date__c = Date.today(),
            Payment_Type__c = 'Cash',
            Invoice__c = inv.Id
        );
        insert pay;


        Test.startTest();
        Boolean success = SyncInvoiceActionHandler.sendPaymentToSage(pay.Id);
        Test.stopTest();

        Assert.isTrue(success, 'The callout was not successful.'); 
    }

    @isTest
    static void postPaymentDraftInvoiceFailure() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            false
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Inntact_GL_Account__c glAcc = new Inntact_GL_Account__c(
            Name = 'Dues',
            Account_Id__c = '40010'
        );
        insert glAcc;
        
        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Follow Up',
            CloseDate = Date.today(),
            Description = 'This is a test',
            Active__c = true,
            ProjectStatus__c = 'Active',
            ProjectType__c = 'Other Restricted',
            ProjectCategory__c = 'Internal Non-billable',
            Location__c = 'NATL',
            Department__c = 'ADM',
            Restrictions__c = '10008',
            Start_Date__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id
        );
        insert opp;

        Invoice__c inv = new Invoice__c(
            Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Restrictions__c = '10008',
            Customer__c = acc.Id,
            State__c = 'Draft'
        );
        insert inv;

        Invoice_Entry__c ie = new Invoice_Entry__c(
            Amount__c = 1000.45,
            GL_Account__c = glAcc.Id,
            Project__c = opp.Id,
            Invoice__c = inv.Id
        );
        insert ie;

        Invoice_Payment__c pay = new Invoice_Payment__c(
            Date__c = Date.today(),
            Payment_Type__c = 'Cash',
            Invoice__c = inv.Id
        );
        insert pay;


        try {
            Test.startTest();
            Boolean success = SyncInvoiceActionHandler.sendPaymentToSage(pay.Id);
            Test.stopTest(); 
        }
        catch (Exception ex) {
            Assert.isNotNull(ex.getMessage(), 'Payment sent to sage while the invoice is in a draft state.');  
        }
    }

    @isTest
    static void postPaymentFailure() {
        MockMultiHttpResponseGenerator mock = new MockMultiHttpResponseGenerator(
            resStore, 
            matchers, 
            false
        );
        Test.setMock(HttpCalloutMock.class, mock);

        Inntact_GL_Account__c glAcc = new Inntact_GL_Account__c(
            Name = 'Dues',
            Account_Id__c = '40010'
        );
        insert glAcc;
        
        Account acc = new Account(
            Name = 'Test Cust',
            Customer_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Follow Up',
            CloseDate = Date.today(),
            Description = 'This is a test',
            Active__c = true,
            ProjectStatus__c = 'Active',
            ProjectType__c = 'Other Restricted',
            ProjectCategory__c = 'Internal Non-billable',
            Location__c = 'NATL',
            Department__c = 'ADM',
            Restrictions__c = '10008',
            Start_Date__c = Date.today(),
            EndDate__c = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Grant' AND SObjectType = 'Opportunity'].Id
        );
        insert opp;

        Invoice__c inv = new Invoice__c(
            Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Restrictions__c = '10008',
            Customer__c = acc.Id,
            State__c = 'Posted'
        );
        insert inv;

        Invoice_Entry__c ie = new Invoice_Entry__c(
            Amount__c = 1000.45,
            GL_Account__c = glAcc.Id,
            Project__c = opp.Id,
            Invoice__c = inv.Id
        );
        insert ie;

        Invoice_Payment__c pay = new Invoice_Payment__c(
            Date__c = Date.today(),
            Payment_Type__c = 'Cash',
            Invoice__c = inv.Id
        );
        insert pay;


        try {
            Test.startTest();
            Boolean success = SyncInvoiceActionHandler.sendPaymentToSage(pay.Id);
            Test.stopTest(); 
        }
        catch (Exception ex) {
            Assert.isNotNull(ex.getMessage(), 'Payment synced with sage with a bad request.');  
        }
    }



}