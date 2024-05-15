public with sharing class AuthNetResponse {

    public String FirstName;
    public String LastName;
    public String Company;
    public String CC;
    public String Exp;
    public String Street;
    public String City;
    public String State;
    public String Zip;
    public String Email;
    public String Phone;
    public String customerProfileId;
    public String paymentProfileId;
    public String subscriptionId;
    public String transId;
    public String networkTransId;
    public String addressVerification;
    public String cvvVerification;
    public Donation detail;

    public static AuthNetResponse parseJSON(String jsonString) {
        return (AuthNetResponse) JSON.deserialize(jsonString, AuthNetResponse.class);
    }

    public class Donation {
        public Boolean isRecurring;
        public Interval recurringInterval;
        public Boolean isHonoree;
        public Honoree honoree;
        public Decimal amount;
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

}