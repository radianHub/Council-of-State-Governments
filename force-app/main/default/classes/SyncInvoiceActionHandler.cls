public with sharing class SyncInvoiceActionHandler {
    
    @AuraEnabled
    public static Boolean sendInvoiceToSage(String id) {
        Invoice_Entry__c[] ieList = [SELECT Id FROM Invoice_Entry__c WHERE Invoice__c = :id];

        if (ieList.size() == 0) {
            throw new AuraHandledException('You need to have at least one invoice entry to sync an invoice to Sage');
        } else {
            return SageIntegrationService.postInvoice(id);
        }

    }

    @AuraEnabled
    public static Boolean sendPaymentToSage(String id){
        Invoice_Payment__c pay = [
            SELECT Invoice__r.State__c 
            FROM Invoice_Payment__c 
            WHERE Id = :id
        ];

        if (pay.Invoice__r.State__c == 'Draft') {
            throw new AuraHandledException('To sync/apply payments to an invoice, the invoice must be in a Posted state.');
        } else {
            return SageIntegrationService.postPayment(id);
        }
    }
}