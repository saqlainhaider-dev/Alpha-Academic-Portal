create database DBProject
go 
use DBProject


create table UserLogin(
	userID int ,
	pass nvarchar(8) not null default '12345678',
	primary key (userID,pass)
)
--drop table UserLogin

create table Admin_Students(
  stdID int identity unique,
  [Name] nvarchar(20) unique ,       
  CNIC nvarchar(19) unique,
  primary key(stdID,[Name])
  
)


create table Admin_Teachers(
  teacherId int identity unique,
  [Name] nvarchar(20) unique,
  courseId nvarchar(20) unique,
  CNIC nvarchar(19) unique,
  primary key (teacherId, [Name])

  
)


  create table Discipline (
	disId int  primary key,
	name nvarchar(25),
)

  go
create table student(
  stdId int unique foreign key references  Admin_Students(stdID),
	[Name] nvarchar(20)unique   foreign key references Admin_Students([Name]),
	fatherName nvarchar(25) not null,
	cnic nvarchar(19)  foreign key references Admin_Students(CNIC),
	dob nvarchar(10) not null,--
	discipline int foreign key references Discipline(disId),
	gender char not null,--
	mobile nvarchar(12) check ( mobile like '03__-%') ,--
	city nvarchar(10),--
  password nvarchar(20) not null,--
  primary key (stdId, [Name])
)
--alter table student
--alter column dob nvarchar (10)

create table Teacher(
	teacherId int unique foreign key references Admin_Teachers(teacherId),
	[Name]  nvarchar(20) unique foreign key references Admin_Teachers([Name]),
	fatherName nvarchar(25) not null,
  courseId int foreign key references Course(courseId),
	cnic nvarchar(19)  foreign key references Admin_Teachers(CNIC),
	dob date not null,
	discipline int foreign key references Discipline(disId),
	gender char not null,
	mobile nvarchar(12) ,
	city nvarchar(10),
  password nvarchar(20) not null,
	email nvarchar(25),
  primary key(teacherId)
)
--alter table teacher
--alter column dob nvarchar(10)

create table Course(
	courseId int primary key,
	name nvarchar(40) unique,
	creditHours int,
  discipline1 nvarchar(20),
  discipline2 nvarchar(20),
  discipline3 nvarchar(20),

)

 
create table Attandence(
	courseId int foreign key references Course(courseId),
	studentID int foreign key references student(stdId), 
	statuss char(1) check (statuss='A' or statuss='P'),
	[day] int ,
	[week] int,

)



create table Marks(
	courseId int foreign key references course(courseId),
	studentID int foreign key references student(stdId),
	quiz int,
	assignment int, 
	sessional1 int,
	sessional2  int,
	finalExam int,
	absolute float,
  discipline int,
  weightage float,
  totalmarks int,
  dateconducted date
)



CREATE  table GrandTotalTable(
    
	  courseId int foreign key references course(courseId),
  	studentID int foreign key references student(stdId),
    finalmarks float,
    finalgrade char(2)
    primary key(studentID,courseId)
  )



create table MonetaryDetails(
  studentID int foreign key references student(stdId),
	Name nvarchar(20)  foreign key references student([Name]),
	AmountPayable int not null,
	DueDate date not null,
  credithourrate int
)
  

create table LostAndFound(
    OwnerID int,
	ArticleId int identity primary key,
	ArticleName nvarchar(25) not null,
	Location nvarchar(30) not null,
	status char check ( status = 'L' or status = 'F'),
	Foreign key (OwnerID) references student(stdId),
	Foreign key (OwnerID) references Teacher(teacherId),
)


create table TaskManager(
    AssignmentId int primary key, 
	courseId int foreign key references course(courseId),
	DueDate date not null,
  Description nvarchar(1000)

)
