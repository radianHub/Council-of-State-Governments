public with sharing class InvoicePaymentController {
    
    @AuraEnabled(cacheable=true)
    public static InvoiceWrapper getInvoice(String id) {
        System.debug(id);
        Invoice__c inv = [
            SELECT
                Customer__c,
                Customer__r.Name,
                Customer__r.Phone,
                Customer__r.Billing_Email__c,
                Customer__r.BillingStreet,
                Customer__r.BillingCity,
                Customer__r.BillingState,
                Customer__r.BillingPostalCode,
                Customer__r.ShippingStreet,
                Customer__r.ShippingCity,
                Customer__r.ShippingState,
                Customer__r.ShippingPostalCode,
                Date__c,
                Invoice_Number__c,
                Amount__c
            FROM
                Invoice__c
            WHERE
                Id = :id
        ];

        List<Invoice_Entry__c> invEntries = [
            SELECT Name, Amount__c
            FROM Invoice_Entry__c
            WHERE Invoice__c = :id
        ];
    
        List<LineItem> items = new List<LineItem>();
        for (Invoice_Entry__c invEntry : invEntries) {
            items.add(new LineItem(
                invEntry.Name,
                invEntry.Amount__c,
                null // * PULL IN DESCRIPTION
            ));
        }

        InvoiceWrapper wrap =  new InvoiceWrapper(
            inv.Customer__r.Name,
            inv.Customer__r.Phone,
            inv.Customer__r.Billing_Email__c,
            new Address(
                inv.Customer__r.BillingStreet,
                inv.Customer__r.BillingCity,
                inv.Customer__r.BillingState,
                inv.Customer__r.BillingPostalCode
            ),
            new Address(
                inv.Customer__r.ShippingStreet,
                inv.Customer__r.ShippingCity,
                inv.Customer__r.ShippingState,
                inv.Customer__r.ShippingPostalCode
            ),
            inv.Date__c,
            inv.Invoice_Number__c,
            inv.Amount__c,
            items
        );
        System.debug(wrap);

        return wrap;
    }

    public class InvoiceWrapper {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String phone;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public Address billTo;
        @AuraEnabled
        public Address shipTo;
        @AuraEnabled
        public Date invDate;
        @AuraEnabled
        public String invNumber;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public LineItem[] lineItems;

        InvoiceWrapper(
            String name,
            String phone,
            String email,
            Address billTo,
            Address shipTo,
            Date invdate,
            String invNumber,
            Decimal amount,
            LineItem[] lineItems
        ) {
            this.name = name;
            this.phone = phone;
            this.email = email;
            this.billTo = billTo;
            this.shipTo = shipTo;
            this.invDate = invDate;
            this.invNumber = invNumber;
            this.amount = amount;
            this.lineItems = lineItems;
        }
    }

    public class Address {
        @AuraEnabled
        public String street;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String zip;
        
        Address(String street, String city, String state, String zip) {
            this.street = street;
            this.city = city;
            this.state = state;
            this.zip = zip;
        }
    }

    public class LineItem {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Decimal amount;
        @AuraEnabled
        public String description;


        LineItem(String name, Decimal amount, String description) {
            this.name = name;
            this.amount = amount;
            this.description = description;
        }
    }
}