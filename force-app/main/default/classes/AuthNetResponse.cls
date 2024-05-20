public with sharing class AuthNetResponse {

    public String cc;
    public String exp;
    public String customerProfileId;
    public String paymentProfileId;
    public String subscriptionId;
    public String transId;
    public String networkTransId;
    public String addressVerification;
    public String cvvVerification;
    public Detail detail;

    public static AuthNetResponse parseJSON(String jsonString) {
        return (AuthNetResponse) JSON.deserialize(jsonString, AuthNetResponse.class);
    }

    public class Detail {
        public Boolean isRecurring;
        public Interval recurringInterval;
        public Boolean isHonoree;
        public Honoree honoree;
        public String campaignId;
        public String contactId;    
        public String invoiceId;
        public String firstName;
        public String lastName;
        public String company;
        public String email;
        public String phone;
        public String street;
        public String city;
        public String state;
        public String zip;
        public Address billTo;
        public Address shipTo;
        public Decimal amount;
        public LineItem[] lineItems;
    }

    public class Interval {
        public Date startDate;
        public String interval;
        public Integer intervalCount;
    }

    public class Honoree {
        public String FirstName;
        public String LastName;
        public String Street;
        public String City;
        public String State;
        public String Zip;
        public String Email;
        public String Phone;
    }

    public class Address {
        public String street;
        public String city;
        public String state;
        public String zip;
    }

    public class LineItem {
        public String name;
        public String description;
        public Decimal amount;
        public String formattedAmount;
    }
}