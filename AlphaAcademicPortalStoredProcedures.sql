create procedure AddMarks            --This procedure add marks for a student of a particular course. The marks can be quiz,assign,mid,final etc any
  @courseid int,
  @studentid int,
  @quizmarks int,
  @assignmentmarks int,
  @mid1marks int,
  @mid2marks int,
  @finalmarks int,
  @grandtotal int,  
  @discipline int,
  @totalmarks int,
  @dateb date    --this will be assigned sysytem date when the porgrams is done.now for ur sake it will be given explicitly by  the user 
  as begin
    
    if @studentid IN (
    SELECT stdId from student
     where discipline = @discipline ) 
      begin 
      declare @myweigh int;
      set @myweigh =0;
      if (@mid1marks is not null or @mid2marks is not null)
        BEGIN
        set @myweigh = 15
        end
      if (@finalmarks is not null)
        BEGIN
        set @myweigh = 50
        end

      
      INSERT INTO Marks Values (@courseid,@studentid,@quizmarks,@assignmentmarks,@mid1marks,@mid2marks,@finalmarks,@grandtotal,@discipline,@myweigh,@totalmarks,@dateb);
      print ('Success');
      END
    else 
      begin 
      print('Error')
      END   

   
  END
  GO

drop PROCEDURE AddMarks   
  
------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure SetQuizWeightage                          -- Procedure that is activated once at  the end of term to assign appropriate weightages 
@weight int ,                                             --- to any number of quizzes
@courseid int
as begin

declare @totalquiz int, @finalweight float;
set @totalquiz =  (                                      --calculating the total no of quizzes conducted for that course

select t.counter from (
select TOP 1 studentID,COUNT(*) as counter
from Marks
where quiz IS NOT null AND courseId = @courseid
group by studentID ) as t )

set @finalweight = CAST(@weight as float) / CAST(@totalquiz as FLOAT)     --Calculating weightage
 

  UPDATE Marks                                          --updating the weightage
  set weightage = @finalweight
  where  quiz is not NULL and courseid = @courseid

END
GO


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure SetAssignmentWeightage                          -- Procedure that is activated once at  the end of term to assign appropriate weightages 
@weight int ,                                             --- to any number of assignments
@courseid int
as begin

declare @totalassignment int, @finalweight float;
set @totalassignment =  (                                      --calculating the total no of assignmets conducted for that course

select t.counter from (
select TOP 1 studentID,COUNT(*) as counter
from Marks
where assignment IS NOT null AND courseId = @courseid
group by studentID ) as t )

set @finalweight = CAST(@weight as float) / CAST(@totalassignment as FLOAT)     --Calculating weightage
 

  UPDATE Marks                                          --updating the weightage
  set weightage = @finalweight
  where  assignment is not null and courseid = @courseid

END
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
create Procedure CalculateGrandTotal                                --a procedure to calculate the final grand total at the end of term and then put that value
@studentid int,                                                    --into the grandtotal table against the apropriate student id
@courseid int                                                                    
as begin

  if (                                                            --checcking if the given student only gave 2 mids
  select t.counter from (
  select studentID, COUNT(*) as counter 
  from Marks
  where studentID = @studentid AND courseId = @courseid AND (sessional1 is not null or sessional2 is NOT NULL)
  group by studentID ) as t  ) = 2
    BEGIN 
    if (                                                          --checking if the given student only gave 1 final
    select t.counter from (
    select studentID, COUNT(*) as counter 
    from Marks
    where studentID = @studentid AND courseId = @courseid AND (finalExam is not null)
    group by studentID ) as t ) = 1 
      BEGIN                 
      UPDATE Marks                                                 --start updating the absolute column in mark table for the given student
      set absolute =  (cast ((ISNULL(assignment,0) + ISNULL(quiz,0) + ISNULL(sessional1,0) + ISNULL(sessional2,0) + ISNULL(finalExam,0)) as float) / cast(totalmarks as float)) * weightage
      where studentID = @studentid AND courseId = @courseid;
      declare @finalmrks float;
      set @finalmrks = ( 
      select t.FinalSum from (
      select studentID, SUM(absolute) As FinalSum                          --calculating the sum of the absolute table and putting it in grantotaltale table
      from Marks 
      where studentID = @studentid AND courseId = @courseid
      group by studentID ) as t )
      INSERT INTO GrandTotalTable VALUES (@courseid, @studentid,@finalmrks,NULL)
      END 
    ELSE 
      BEGIN
      print('ERROR. Number of final exams not valid' )
      END 

  END
  end
  

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure calculategrade                       --calculates grades against courseids in GrandTotalTable
  @studentid int,
  @courseid int
  as begin


  declare @grade char(2),@number float;

  set @number = (
  select finalmarks
  from GrandTotalTable
  where studentID = 2 AND courseId = @courseid )

 
     If @number > 90
      Begin 
      set @grade = 'A'
      end 
    else if   @number < 89 AND @number >= 80
      begin
     set  @grade = 'A-'
      end
     else if  @number < 79 AND @number >= 75
      begin
    set  @grade = 'B+'
      end
     else if  @number < 74 AND @number >= 70
      begin
    set  @grade = 'B'
      end
    else if  @number < 69 AND @number >= 65
      begin
    set @grade = 'B-'
      end
    else if  @number < 64 AND @number >= 60
      begin
     set @grade = 'C+'
      end
    else if  @number < 59 AND @number >= 50
      begin
    set  @grade = 'C'
      end
   else 
        begin 
        set @grade = 'F'
        END
        
  
   Update GrandTotalTable
   set finalgrade = @grade
   where @studentid = studentID AND @courseid = courseId


  END GO 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure ModifyQuizMarks
  @studentid int,
  @courseid int,
  @newmarks int,
  @discipline int,
  @dateb date

  as begin

    if @studentid IN (
    SELECT stdId from student
     where discipline = @discipline ) 
      begin
      update Marks
      set quiz = @newmarks 
      where @dateb = dateconducted AND quiz is not null  AND studentID = @studentid AND @courseid = courseId
                        


      END 
end GO

--Note that these odify functions shall not change absolutes in marks table as absolutes are only put at th end of term when no modification is allowed

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure ModifyAssignmentMarks
  @studentid int,
  @courseid int,
  @newmarks int,
  @discipline int,
  @dateb date

  as begin

    if @studentid IN (
    SELECT stdId from student
     where discipline = @discipline ) 
      begin
      update Marks
      set assignment = @newmarks 
      where @dateb = dateconducted AND assignment is not null AND studentID = @studentid AND @courseid = courseId
                        


      END 
end GO

drop PROCEDURE ModifyAssignmentMarks


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure ModifySessional1Marks
  @studentid int,
  @courseid int,
  @newmarks int,
  @discipline int,
  @dateb date

  as begin

    if @studentid IN (
    SELECT stdId from student
     where discipline = @discipline ) 
      begin
      update Marks
      set sessional1 = @newmarks 
      where @dateb = dateconducted AND sessional1 is not null  AND studentID = @studentid AND @courseid = courseId
                        


      END 
end GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure ModifySessional2Marks
  @studentid int,
  @courseid int,
  @newmarks int,
  @discipline int,
  @dateb date

  as begin

    if @studentid IN (
    SELECT stdId from student
     where discipline = @discipline ) 
      begin
      update Marks
      set sessional2 = @newmarks 
      where @dateb = dateconducted AND sessional2 is not null  AND studentID = @studentid AND @courseid = courseId
                        


      END 
end GO



---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure ModifyFinalMarks
  @studentid int,
  @courseid int,
  @newmarks int,
  @discipline int,
  @dateb date

  as begin

    if @studentid IN (
    SELECT stdId from student
     where discipline = @discipline ) 
      begin
      update Marks
      set finalExam = @newmarks 
      where @dateb = dateconducted AND finalExam is not null AND studentID = @studentid AND @courseid = courseId
                        


      END 
end GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure CalculateGPA                    --A procedure to calculate GPA of a particular student
@studentid int,
@gpa float OUTPUT
as begin



declare @discip int ;                        --finding the discipline in which the student has been enrolled
set @discip = (
select discipline from student
where stdId = @studentid) 
--select @discip
declare @totalcreds int ;
 
if @discip = 1                                                           --this calculates the total credit hrs of the discipline that student is enroled in
  begin 
  set @totalcreds = ( select t.COUN from (
  select discipline1, SUM(creditHours) as COUN
  from Course
  where discipline1 = @discip
  group by  discipline1 ) as t )
end 


else if @discip = 2 
begin 
set @totalcreds = ( select t.COUN from (
select discipline2, SUM(creditHours) as COUN
from Course
where discipline2 = @discip
group by  discipline2 ) as t )
end

if @discip = 3 
begin 
set @totalcreds = ( select t.COUN from (
select discipline3, SUM(creditHours) as COUN
from Course
where discipline3 = @discip
group by  discipline3 ) as t )
end

--select @totalcreds
if object_id('table2') IS NULL 
BEGIN

 create table table2 (                             --temporary table being created to calculate gpa
  course int UNIQUE,
  studentid int,
 
  grade char(2),
  value1 float,
  value2 float,
  creds int
  );
END

INSERT INTO table2                                                              --inserting into temporary table the values specific to the student given
  select Course.courseId,GrandTotalTable.studentID, finalgrade,0,0,credithours
  from GrandTotalTable join Course ON GrandTotalTable.courseId=Course.courseId 
    where studentID = @studentid;


UPDATE table2                                         --setting up grade points for grades recieved
  set value2 =  4 where grade = 'A'
UPDATE table2
  set value2 =  3.67 where grade = 'A-'
  UPDATE table2
  set value2 =  3.33 where grade = 'B+'
  UPDATE table2
  set value2 =  3.0 where grade = 'B'
    UPDATE table2
  set value2 =  2.67 where grade = 'B-'
    UPDATE table2
  set value2 =  2.33 where grade = 'C+'
    UPDATE table2
  set value2 =  2 where grade = 'C'
      UPDATE table2
  set value2 =  0 where grade = 'F'
 
        Update table2 set value1 = value2*creds                 --calculating the total credits earned by student
 

                
declare @totalfinal float;
set @totalfinal = ( select SUM(value1) 
                from table2
                group by studentid)

set @gpa = @totalfinal / @totalcreds             --gpa
--select @gpa
delete from table2

end 
go



---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 create procedure CreateStudent                                 --Admin Specific proc to create a student 
  @Name nvarchar(20),       
  @CNIC nvarchar(19)
  as BEGIN
  if (@Name not IN ( select [Name] from Admin_Students )) AND (@CNIC not in ( select cnic from Admin_Students))
    BEGIN
    INSERT INTO Admin_Students Values (@Name,@CNIC);
    end
  else
    print('Error The student alreday exists')

  end GO



---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure CreateTeacher                                  --Admin Specific proc to create a teacher
  @Name nvarchar(20),      
  @CNIC nvarchar(19)
  as BEGIN
  if (@Name not IN ( select [Name] from Admin_Students )) AND (@CNIC not in ( select cnic from Admin_Students))
    BEGIN
    INSERT INTO Admin_Students Values (@Name,@CNIC);
    end
  else
    print('Error The student alreday exists')

  end GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure AddItemLostAndFound                        --An admin specific proc. Adds a lost item ino the lostandfound table
  @OwnerID int,
	@ArticleName nvarchar(25),
	@Location nvarchar(30),
	@status char
  as begin

  if @OwnerID IN ( select stdid from Admin_Students) AND @status = 'L'
    begin
    insert into LostAndFound Values (@ownerid,@ArticleName,@Location,@status) ;
    END

  END
    go



---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure DeleteItemLostAndFound                        --An admin specific proc. Deletes a lost item ino the lostandfound table once it is found
  @articleid int,
	@ArticleName nvarchar(25)
  as begin

  if @articleid IN ( select articleid from LostandFound where @articlename = articlename )
    begin
    delete from LostAndFound where @articleid = articleid and @articlename = articlename
      print('Success')
    END
  else
    print('Error')

  END
    go

  drop PROCEDURE DeleteItemLostAndFound


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
  create procedure GetPositionHolders                 --this procedure returns the top 3 students based on gpa in a discipline
        @discipline int ,
    @post1 int OUTPUT,
    @post2 int OUTPUT,
    @post3 int OUTPUT

    as begin
      if object_id('finalgpa') is null 
        begin
  create table finalgpa (
    studentid int unique,
    gpa float
    )
    end
  
      Insert into finalgpa(studentID)
      select distinct studentid from GrandTotalTable
        Intersect
       select stdId  from student where discipline = @discipline
        
 
        declare @counter1 int;
        declare @stdid int;
        DECLARE @totals int ;
        Declare @gpafound float;
        set @totals = (select SUM(pp.p) from (select t.p from (
        select COUNT(*) as p,studentid
        from finalgpa
        group by studentid)t)pp)
    
        set @counter1 = 1;
        begin 
          while ( @counter1<=@totals)
            begin
              set @stdid = (   select t.st from (select Dense_rank() over (order by studentid) as num,studentid as st from finalgpa)t where @counter1 = t.num)
               
              execute  CalculateGpa
                @studentid = @stdid,
                @gpa = @gpafound OUTPUT
                
                 update finalgpa set gpa = @gpafound
                  where @stdid = finalgpa.studentid
              set @counter1  = @counter1+ 1
 

            end
         end

select * from finalgpa
set @post1 =  (  select  t.st from (select Dense_rank() Over ( order by gpa desc ) as Noum,gpa,studentid as st from finalgpa)t where t.Noum = 1)

set @post2 = (  select  t.st from (select Dense_rank() Over ( order by gpa desc ) as Noum,gpa,studentid as st from finalgpa)t where t.Noum = 2)

  set @post3 = (  select  t.st from (select Dense_rank() Over ( order by gpa desc ) as Noum,gpa,studentid as st from finalgpa)t where t.Noum = 3)
drop table finalgpa
 -- drop view studentstemp
  end

drop procedure Getpositionholders
    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 create procedure  GetwarningStudents                              --outputs the stdents currently having gpa < 2
  @discipline int
    as begin
    if object_id('finalgpa') is null 
        begin
  create table finalgpa (
    studentid int unique,
    gpa float 
    )
    end
      --drop table finalgpa
      Insert into finalgpa(studentID)
      select distinct studentid from GrandTotalTable
           Intersect
       select stdId  from student where discipline = @discipline

        
     

        declare @counter1 int;
        declare @stdid int;
        DECLARE @totals int ;
        Declare @gpafound float;
        set @totals = (select SUM(pp.p) from (select t.p from (
        select COUNT(*) as p,studentid
        from finalgpa
        group by studentid)t)pp)
        --select @totals
        

--select * from studentstemp
        set @counter1 = 1;
        begin 
          while ( @counter1<=@totals)
            begin
              set @stdid = (   select t.st from (select Dense_rank() over (order by studentid) as num,studentid as st from finalgpa)t where @counter1 = t.num)
               
              execute  CalculateGpa
                @studentid = @stdid,
                @gpa = @gpafound OUTPUT
            

                update finalgpa set gpa = @gpafound 
                 where @stdid = finalgpa.studentid
                 
              set @counter1  = @counter1+ 1


            end
         end

select * from finalgpa
where gpa < 2

drop table finalgpa
end


drop procedure getwarningstudents


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure changepassofstudent                             --A procedure to change the password of a student 
@a int ,
@pas nvarchar(20)
as
if @a in (select stdID from student)
begin
if @pas!=  (select [password] from student where stdID=@a)
begin
update student set [password]=@pas where stdID=@a
end
else
begin
  print('same password entered')
end
end
else
begin
print('student do not exist ; stdid not correct')
end


drop procedure changepassofstudent



---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure changepassofteacher                           --A procedure to change the password of a teacher
@a int ,
@pas nvarchar(20)
as
if @a in (select teacherId from Teacher)
begin
if @pas!=  (select [password] from Teacher where teacherId=@a)
begin
print('passwod updated')
update Teacher set [password]=@pas where teacherId=@a
end
end
else
begin
print('teacher do not exist ')
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure changemailofteacher                        --A procedure to change the email of a teacher
@a int ,
@mal nvarchar(25)
as
if @a in (select teacherId from Teacher)
begin
if @mal !=  (select email from Teacher where teacherId=@a)
begin
print('email updated')
update Teacher set email=@mal where teacherId=@a
end
end
else
begin
print('teacher do not exist ')
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure changemobileofteacher                         --A procedure to change the mobile Number of a teacher
@a int ,
@mob nvarchar(12)
as
if @a in (select teacherId from Teacher)
begin
if @mob !=  (select mobile from Teacher where teacherId=@a)
begin
print('mobile number updated')
update Teacher set mobile=@mob where teacherId=@a
end

end
else
begin
print('teacher do not exist ')
end




----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

go
create procedure Modify_CreditHourRate                            --this procedure modifies the credit hour rate of a course that a student is studying
@credithour int,
@stdId int
AS
begin
	update monetaryDetails
	SET credithourrate=@credithour 
	where studentID=@stdId
End

execute dbo.Modify_CreditHour
@credithour=2300,
@stdId=31

drop procedure Modify_Challan_Duedate

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure Modify_Challan_Duedate                           --this procedure modifies the Challan due date for submission of fees for a particular student
@duedate date,
@stdId int
as
begin
	update monetaryDetails
	SET DueDate=@duedate 
	where studentID=@stdId and @duedate > GETDATE()
End



drop procedure CalculateAmountPayable

------------------------------------------------------------------------------------------------------------------------------------------++---------------------------
create procedure CalculateAmountPayable                       --This procedure calculates the fees for a particular student  and inserts the amount into the monetary details table                    
@stdId                    
AS
begin
if exists (Select discipline from student where stdId=@stdId and discipline=1)
begin
	update monetaryDetails
	SET AmountPayable =(Select credithourrate*stc.TotalCreditHours as AmountPayable from monetaryDetails,
	(select Sum(total) AS TotalCreditHours,ST.d AS S from(Select t.c*t.v AS total,t.discipline1 as d from 
	(Select Count(*) c,discipline1,creditHours as v from Course
	where discipline1=1
	group by discipline1,creditHours)t)st
	group by st.d)stc where studentID=@stdId)
	where studentID=@stdId	
end

if exists (Select discipline from student where stdId=@stdId and discipline=2)
begin
	update monetaryDetails
	SET AmountPayable = (Select credithourrate*stc.TotalCreditHours as AmountPayable from monetaryDetails,
	(select Sum(total) AS TotalCreditHours,ST.d AS S from(Select t.c*t.v AS total,t.discipline2 as d from 
	(Select Count(*) c,discipline2,creditHours as v from Course
	where discipline2=2
	group by discipline2,creditHours)t)st
	group by st.d)stc where studentID=@stdId)
	where studentID=@stdId	
end

if exists (Select discipline from student where stdId=@stdId and discipline=3)
begin
	update monetaryDetails
	SET AmountPayable = (Select credithourrate*stc.TotalCreditHours as AmountPayable from monetaryDetails,
	(select Sum(total) AS TotalCreditHours,ST.d AS S from(Select t.c*t.v AS total,t.discipline3 as d from 
	(Select Count(*) c,discipline3,creditHours as v from Course
	where discipline3=3
	group by discipline3,creditHours)t)st
	group by st.d)stc where studentID=@stdId)
	where studentID=@stdId	
end
end



--------------------------------------------------------------------------------------------------------------------------------+++-------------------------------------
drop procedure EnableChallan

create procedure EnableChallan                                   --An admin specific procdure that appon the approvalof admins, enables the challan for
as
begin	
	execute dbo.CalculateAmountPayable
	@stdId=@stId
end




---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure AddAssignment                                    --this procedure adds an assignment task in the task manager table(only teachercan)
@id int,
@courseId int,
@duedate date,
@desc nvarchar(1000)
as 
begin 
	if @duedate>GETDATE() and exists (Select courseId from Course where courseId=@courseId)
	Insert Into TaskManager Values(@id,@courseId,@duedate,@desc)
end



---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure Modify_Assingnment_Duedate                       --this procedure changes the due date for an assignment alreay assigned
@duedate date,
@assId int
as
begin
	update TaskManager
	SET DueDate=@duedate 
	where AssignmentID=@assId and @duedate > GETDATE()
End


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
create procedure DeleteAssignment                                                --this procedure delete from task manager as assignment once its due date has passed
@assId int
as
begin
	delete from TaskManager where @assId =  AssignmentId
End


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
go
create procedure spStdSignup                                                    --this procedure creates an account for a student that is already enrolled(present in admin_students)

@Name nvarchar(20), @cnic nvarchar(19), @stdId int, @fatherName nvarchar(25), @dob nvarchar(10), @discipline int,
 @gender char ,
 @mobile nvarchar(12),
 @city nvarchar(10),
 @password nvarchar(20),
 @status int out
As
Begin
	--declare @status int;
	select @Name = (select Name from Admin_Students where StdID = @stdID and CNIC = @Cnic)
	if	@Name is not null
	begin
		set @status = 1
	end
	
	else
	begin				
		set @status = 0
	end

	if	@status = 1
	begin

		insert into Student values(@stdId,@Name,@fatherName,@cnic,@dob,@discipline,@gender,@mobile,@city,@password)
		insert into UserLogin values(@stdId,@password);
	end
	else

	begin
		print 'Student Does Not Found!'
	end
	
End

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
go
create procedure spTeacherSignup                                            --this procedure creates an account for a teacher that is already hired(present in admin_teachers)

@courseId nvarchar(20),
@name nvarchar(20),
 @cnic nvarchar(19),
  @teacherId int, 
  @fatherName nvarchar(25),
   @dob nvarchar (10),
    @discipline int,
 @gender char ,
 @mobile nvarchar(12),
 @city nvarchar(10),
 @password nvarchar(20),
 @email nvarchar(25),
 @status int out
As
Begin
	--declare @status int;
	select @name = (select Name from Admin_Teachers where teacherId = @teacherId and CNIC = @cnic and @courseId = courseId)
	if	@name is not null
	begin
		set @status = 1
	end
	
	else
	begin				
		set @status = 0
	end

	if	@status = 1
	begin

		insert into Teacher values(@teacherId,@name,@fatherName,@courseId,@cnic,@dob,@discipline,@gender,@mobile,@city,@password,@email)
	end
	else

	begin
		print 'Teacher Does Not Found!'
	end
	
End

--drop proc spTeacherSignup


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 create proc spAddAttandance                                                 --this procedure adds a particular students attendance

 @courseId int,@studentId int,@status char(1),@day int ,@week int

 as 
 begin 
	insert into Attandence values (@CourseId,@studentId,@status,@day,@week)
 end


 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 create proc spGetAttandanceByCourse                                  --this procedure gets the attedance of a course
 @courseId int
 As
 Begin
	Select * from Attandence where courseId = @courseId
 End

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 create proc spCalculateAttandenceInaCourse                               --this procedure returns the attendance % of aa student in a course
 @studentId int,@courseId int,
 @count int out
 As
 Begin
	declare @noOfLectures int 
	Select @noOflectures = (Select count(courseId) from Attandence where courseId = @courseId)
	Select @count = (Select count(*) from Attandence where studentId = @studentId and courseId = @courseId)
	set @count = ((@count / @noOfLectures)*100)
 End

 --------------------------------------------------------------------------------------
 create proc spUserLogin
 @userId int,@password nvarchar(25),@status int out
as
	 begin
		select @userId = (select userId from userLogin where userID=@userId and pass = @password)
		if @userId is not null

		begin 
		set @status = 1
		end

		else

		begin
		set @status=0
		end
	 end