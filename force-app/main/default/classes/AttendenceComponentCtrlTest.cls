@isTest
public class AttendenceComponentCtrlTest{

        @testSetup static void setup() {
        
           hed__Course__c course =  TestDataFactory.createCourse(true);
           
           hed__Course_Offering__c courseOffering =  TestDataFactory.createCourseOffering(true,course.Id);
           TestDataFactory.creteStudentEnrollment(true,courseOffering.Id);
        
        }
        
        
         @isTest static void getAssociatedClassDetails() {
             hed__Course_Offering__c courseOffering = [SELECT Id FROM hed__Course_Offering__c LIMIT 1];
             Test.startTest();
                 AttendenceComponentCtrl.getAssociatedClassDetails(false,courseOffering.Id);
             Test.stopTest();
         }
         
         @isTest static void getAssociatedClassDetailsForCommunityUser() {
             hed__Course_Offering__c courseOffering = [SELECT Id FROM hed__Course_Offering__c LIMIT 1];
             Test.startTest();
                 AttendenceComponentCtrl.getAssociatedClassDetails(true,courseOffering.Id);
             Test.stopTest();
         }

        @isTest static void getEnrolledStudents() {
            system.debug('ENROLLED'+[SELECT id,hed__Status__c,Status_Effective__c FROM hed__Course_Enrollment__c]);
             hed__Course_Offering__c courseOffering = [SELECT Id FROM hed__Course_Offering__c LIMIT 1];
             Test.startTest();
                 AttendenceComponentCtrl.getEnrolledStudents(courseOffering.Id,System.today().addDays(3));
             Test.stopTest();
         }
         
         
         @isTest static void createAttendenceEvents() {
             hed__Course_Offering__c courseOffering = [SELECT Id FROM hed__Course_Offering__c LIMIT 1];
             Test.startTest();
               List< AttendenceComponentCtrl.attendenceDetails> attendenceDetails =   AttendenceComponentCtrl.getEnrolledStudents(courseOffering.Id,System.today().addDays(3));              
               AttendenceComponentCtrl.createAttendenceEvents(JSON.serialize(attendenceDetails),System.today().addDays(3));
             Test.stopTest();
         }
         
         
         @isTest static void createAttendenceEvents_1() {
             hed__Course_Offering__c courseOffering = [SELECT Id FROM hed__Course_Offering__c LIMIT 1];
               List< AttendenceComponentCtrl.attendenceDetails> attendenceDetails =   AttendenceComponentCtrl.getEnrolledStudents(courseOffering.Id,System.today().addDays(3));              
               AttendenceComponentCtrl.createAttendenceEvents(JSON.serialize(attendenceDetails),System.today().addDays(3));
          
             Test.startTest();
               List< AttendenceComponentCtrl.attendenceDetails> existingattendenceDetails =   AttendenceComponentCtrl.getEnrolledStudents(courseOffering.Id,System.today().addDays(3));              
               AttendenceComponentCtrl.createAttendenceEvents(JSON.serialize(existingattendenceDetails),System.today().addDays(3));
          
             Test.stopTest();
         }




}