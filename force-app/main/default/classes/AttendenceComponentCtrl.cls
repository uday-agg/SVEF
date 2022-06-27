public without sharing class AttendenceComponentCtrl {

    
    @AuraEnabled
    public static List<Map<String,Object>> getAssociatedClassDetails(Boolean isFromCommunity,String selectedCourseId){
        List<Map<String,Object>> classesList = new List<Map<String,Object>>();
        classesList.add(new Map<String,Object>{
           'label'=>'--None--',
           'value'=>''   
        });
        User loggedinUser = [SELECT Id,ContactId FROM User WHERE Id=:userInfo.getUserId() LIMIT 1];
        //12/21/21 - Abhi Adding Start Date and End Date filters to SOQL to get only active courses
        Date todayDate = System.Date.today();
        if(isFromCommunity){
        for(hed__Course_Enrollment__c eachCourceEnrollment:[SELECT Id,hed__Course_Offering__c,hed__Course_Offering__r.Name FROM hed__Course_Enrollment__c WHERE hed__Contact__c=:loggedinUser.ContactId and Start_Date__c <= :todayDate and End_Date__c >= :todayDate]){
            classesList.add(new Map<String,Object>{
               'label'=>eachCourceEnrollment.hed__Course_Offering__r.Name,
                'value'=>eachCourceEnrollment.hed__Course_Offering__c  
            });
        }
        }else{
            system.debug('selectedCourseId>> '+selectedCourseId);
            hed__Course_Offering__c courseOffering = [SELECT Id,Name  FROM hed__Course_Offering__c WHERE Id=:selectedCourseId LIMIT 1];
             classesList.add(new Map<String,Object>{
               'label'=>courseOffering.Name,
                'value'=>courseOffering.Id  
            });
        }
        
        return classesList;
    }   
    
    @auraEnabled
    public static List<attendenceDetails> getEnrolledStudents(Id courseId,Date attendenceDate){
       system.debug('attendenceDate '+attendenceDate); 
       string runningWeekDay = DateTime.newInstance(attendenceDate, Time.newInstance(0, 0, 0, 0)).format('EEEE');
       date attendenceSearchDate = attendenceDate.addDays(1);
       hed__Course_Offering__c  co = [SELECT id,Program_Day_s__c FROM hed__Course_Offering__c  WHERE Id=:courseId];
        if(!co.Program_Day_s__c.contains(runningWeekDay)){
            
            string errorMessage = 'Attendence not required';
            AuraHandledException auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } 
       List<Course_Holiday__c > courseHoliday = [SELECT Id, Notes__c  FROM Course_Holiday__c  WHERE Course_Offering__c =:courseId AND Date__c =:attendenceSearchDate]; 
       
        if(courseHoliday!=null && !courseHoliday.isEmpty()){
            string errorMessage = courseHoliday[0].Notes__c;
            AuraHandledException auraEx = new AuraHandledException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } 
       List<attendenceDetails> attendenceDetailsList = new List<attendenceDetails>();
       List<hed__Course_Enrollment__c> enrolledStudents =  [SELECT Id,hed__Contact__r.Abbreviated_Name__c,hed__Contact__c,hed__Contact__r.FirstName,hed__Contact__r.LastName FROM hed__Course_Enrollment__c WHERE hed__Course_Offering__c=:courseId AND RecordType.DeveloperName='Student' AND hed__Status__c='Enrolled' AND Status_Effective__c <=:attendenceSearchDate ORDER BY hed__Contact__r.FirstName ];
       Map<Id,hed__Attendance_Event__c> availableAttendece = getSelectedDateAttendence(courseId,attendenceDate);
        for(hed__Course_Enrollment__c eachEnrolledStudent:enrolledStudents){
            attendenceDetails eachSADetails = new attendenceDetails();
            eachSADetails.studentName = eachEnrolledStudent.hed__Contact__r.FirstName +' '+eachEnrolledStudent.hed__Contact__r.LastName;
            eachSADetails.nickName = eachEnrolledStudent.hed__Contact__r.Abbreviated_Name__c; 
            eachSADetails.contactId = eachEnrolledStudent.hed__Contact__c;
            eachSADetails.courseEnrollmentId = eachEnrolledStudent.Id;
            eachSADetails.attendence = '';
           // eachSADetails.absent = false;
            eachSADetails.reason = '';
            eachSADetails.reasonDescription = '';
            if(availableAttendece.containsKey(eachEnrolledStudent.hed__Contact__c)){
                hed__Attendance_Event__c relatedAttendence = availableAttendece.get(eachEnrolledStudent.hed__Contact__c);
                eachSADetails.attendence = relatedAttendence.hed__Attendance_Type__c;
                    //relatedAttendence.hed__Attendance_Type__c=='Present'?true:false;
            //  eachSADetails.absent =  relatedAttendence.hed__Attendance_Type__c=='Absent'?true:false;
                
                eachSADetails.reason = relatedAttendence.hed__Reason__c;
                eachSADetails.reasonDescription = relatedAttendence.hed__Reason_Description__c;
                eachSADetails.AttendanceEventId = relatedAttendence.Id;
            }
            attendenceDetailsList.add(eachSADetails);
            
        }
       return attendenceDetailsList;
    }
    
    public static Map<Id,hed__Attendance_Event__c> getSelectedDateAttendence(Id courseEnrollmentId,Date attendenceDate){
        Id courseId = [SELECT Id,hed__Course__c FROM hed__Course_Offering__c WHERE Id=:courseEnrollmentId].hed__Course__c;
        Map<Id,hed__Attendance_Event__c> attendence = new Map<Id,hed__Attendance_Event__c>();
        for(hed__Attendance_Event__c eachStudentAttendence:[SELECT Id,hed__Attendance_Type__c,hed__Contact__c,hed__Reason__c,hed__Reason_Description__c FROM  hed__Attendance_Event__c WHERE hed__Date__c=:attendenceDate AND hed__Course_Connection__r.hed__Course_Offering__r.hed__Course__c=:courseId]){
            attendence.put(eachStudentAttendence.hed__Contact__c,eachStudentAttendence);
        }
        return attendence;
    }
    
    public class attendenceDetails{
        @AuraEnabled
            public string studentName ;
        @AuraEnabled
            public string nickName ;
        @AuraEnabled
            public Id contactId ;
        @AuraEnabled
            public Id courseEnrollmentId ;
         @AuraEnabled
            public Id AttendanceEventId ;
          @AuraEnabled
            public string reason ;
         @AuraEnabled
            public string reasonDescription ;
        @AuraEnabled
            public string attendence ;
        
    }
    
    @auraEnabled
    public static void createAttendenceEvents( String attendenceDetailsString,Date attendenceDate){
        List<attendenceDetails>  attendenceDetails = (List<attendenceDetails>)JSON.deserialize(attendenceDetailsString, List<attendenceDetails>.class);
        system.debug('attendenceDetails ++ '+attendenceDetails);
        List<hed__Attendance_Event__c> attendence = new List<hed__Attendance_Event__c>();
        
        for(attendenceDetails eachStudent : attendenceDetails){
            hed__Attendance_Event__c eachStudentAttendence = new hed__Attendance_Event__c();
            if(eachStudent.AttendanceEventId!=null){ eachStudentAttendence.Id =  eachStudent.AttendanceEventId;    
            }
            eachStudentAttendence.hed__Date__c = attendenceDate;
            eachStudentAttendence.hed__Reason__c = eachStudent.reason;
            eachStudentAttendence.hed__Reason_Description__c = eachStudent.reasonDescription;
            eachStudentAttendence.hed__Attendance_Type__c = eachStudent.attendence;
            eachStudentAttendence.hed__Contact__c = eachStudent.contactId;
            eachStudentAttendence.hed__Course_Connection__c = eachStudent.courseEnrollmentId;
            attendence.add(eachStudentAttendence);
        }
        system.debug('attendence list '+attendence);
        if(!attendence.isEmpty())
            upsert attendence;
    }
}
