USE [master]
GO
/****** Object:  Database [BranchSales2022]    Script Date: 2/5/2023 8:55:59 PM ******/
CREATE DATABASE [BranchSales2022]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'BranchSales', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\BranchSales2022.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'BranchSales_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\BranchSales2022_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [BranchSales2022] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [BranchSales2022].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [BranchSales2022] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [BranchSales2022] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [BranchSales2022] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [BranchSales2022] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [BranchSales2022] SET ARITHABORT OFF 
GO
ALTER DATABASE [BranchSales2022] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [BranchSales2022] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [BranchSales2022] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [BranchSales2022] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [BranchSales2022] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [BranchSales2022] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [BranchSales2022] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [BranchSales2022] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [BranchSales2022] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [BranchSales2022] SET  DISABLE_BROKER 
GO
ALTER DATABASE [BranchSales2022] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [BranchSales2022] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [BranchSales2022] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [BranchSales2022] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [BranchSales2022] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [BranchSales2022] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [BranchSales2022] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [BranchSales2022] SET RECOVERY FULL 
GO
ALTER DATABASE [BranchSales2022] SET  MULTI_USER 
GO
ALTER DATABASE [BranchSales2022] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [BranchSales2022] SET DB_CHAINING OFF 
GO
ALTER DATABASE [BranchSales2022] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [BranchSales2022] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [BranchSales2022] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [BranchSales2022] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'BranchSales2022', N'ON'
GO
ALTER DATABASE [BranchSales2022] SET QUERY_STORE = OFF
GO
USE [BranchSales2022]
GO
/****** Object:  User [Usernew]    Script Date: 2/5/2023 8:56:00 PM ******/
CREATE USER [Usernew] FOR LOGIN [User] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_IsAchivedTarget]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[FN_IsAchivedTarget]
(
    @TransactionId int -- لازم احطه مشان استخدمه داخل ال function 
)
returns bit  -- what the function will returns data type 
as
begin
declare @BranchId int , @ProductId int ,@Amount decimal(15,3),@CNT decimal(15,3),@year char(4), 
        @TargetAmount decimal (15,3),@TargetCNT int,@TargetYear char(4),@IsAchive bit

		-- retrieve branchid & productid from transaction table for dynamic transactionid,branchid,productid
		select @BranchId = BranchId, @ProductId = Productid -- what is the product & branch for transactionid
		from [Transaction]
		where Transactionid = @TransactionId

		-- retrieve amount,cnt,year from target table for dynamic branchid,productid
		select @TargetAmount = Amount,@TargetCNT = CNT,@TargetYear = [year]
		from [Target]
		where BranchId = @BranchId and ProductId = @ProductId
		
	   -- retrieve sum of amount and count for cnt  from target transaction table for dynamic branchid,productid
		select @Amount = sum (amount),@cnt = count (*)
		from [Transaction]
		where BranchId = @BranchId and ProductId = @ProductId and StatusId = 2 and year(TrDate) = @TargetYear
		group by BranchId,ProductId
		

		if @TargetAmount<= @Amount and @TargetCNT <= @CNT
		begin 
		 set @IsAchive = 1
		 end 
		 else 
		 begin 
		 set @IsAchive = 0
		 end 
		 
return @IsAchive 
end
GO
/****** Object:  Table [dbo].[TransactionFlow]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionFlow](
	[FlowId] [int] IDENTITY(1,1) NOT NULL,
	[FlowDesc] [varchar](50) NOT NULL,
	[FlowOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_TransactionFlow] PRIMARY KEY CLUSTERED 
(
	[FlowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Transaction]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transaction](
	[TransactionId] [int] IDENTITY(1,1) NOT NULL,
	[Amount] [decimal](15, 3) NOT NULL,
	[BranchId] [int] NULL,
	[ProductId] [int] NULL,
	[UserId] [int] NULL,
	[StatusId] [int] NULL,
	[FlowId] [int] NULL,
	[CustomerId] [int] NULL,
	[TrDate] [datetime] NOT NULL,
 CONSTRAINT [PK_TransactionId] PRIMARY KEY CLUSTERED 
(
	[TransactionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AuditTrailLog]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AuditTrailLog](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TransactionDesc] [varchar](max) NOT NULL,
	[UserId] [int] NOT NULL,
	[TransactionDate] [datetime] NOT NULL,
 CONSTRAINT [PK_AuditTrailLog] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [int] NOT NULL,
	[UserName] [varchar](50) NOT NULL,
	[Branchid] [int] NULL,
	[Password] [varchar](50) NOT NULL,
	[EFullName] [varchar](50) NOT NULL,
	[AFullName] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[EmployeeId] [int] NOT NULL,
	[UserTypeId] [int] NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Status]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Status](
	[StatusId] [int] IDENTITY(1,1) NOT NULL,
	[StatusDesc] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_Status] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[transactionbyid]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[transactionbyid]
 as 
 select  t.TransactionId,a.TransactionDate , u.EFullName, s.StatusDesc,tf.FlowDesc 
from AuditTrailLog a 
inner join [Transaction] t on a.UserId=t.UserId
inner join Users U on u.UserId = t.UserId
inner join TransactionFlow TF on tf.FlowId=t.FlowId 
inner join [Status] S on t.StatusId=s.StatusId 
GO
/****** Object:  UserDefinedFunction [dbo].[getby]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE function [dbo].[getby](@transactionid int)
 returns table 
 as
 return
 select  * from [transactionbyid] 
where TransactionId = @TransactionId 
GO
/****** Object:  Table [dbo].[Branchs]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Branchs](
	[BranchId] [int] IDENTITY(1,1) NOT NULL,
	[BranchEName] [varchar](50) NOT NULL,
	[BranchAName] [nvarchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[BranchAddress] [nvarchar](100) NULL,
 CONSTRAINT [PK_Branchs] PRIMARY KEY CLUSTERED 
(
	[BranchId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ArchivedTransactions]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ArchivedTransactions](
	[TransactionId] [int] NOT NULL,
	[Amount] [decimal](15, 3) NOT NULL,
	[BranchId] [int] NULL,
	[ProductId] [int] NULL,
	[UserId] [int] NULL,
	[StatusId] [int] NULL,
	[FlowId] [int] NULL,
	[CustomerId] [int] NULL,
	[TrDate] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Customers]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customers](
	[CustomerId] [int] IDENTITY(1,1) NOT NULL,
	[CustomerEName] [varchar](50) NOT NULL,
	[BranchId] [int] NULL,
	[CustomerAName] [nvarchar](50) NOT NULL,
	[DOB] [date] NOT NULL,
	[NationalNo] [char](10) NOT NULL,
	[Email] [varchar](50) NOT NULL,
	[PhoneNo] [char](12) NULL,
	[Income] [decimal](15, 3) NULL,
 CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Product]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product](
	[ProductId] [int] IDENTITY(1,1) NOT NULL,
	[ProductEDesc] [varchar](50) NOT NULL,
	[ProductADesc] [nvarchar](50) NOT NULL,
	[IsActive] [nchar](10) NOT NULL,
 CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[TransactionView]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[TransactionView]
as
select tr.TransactionId,
 c.CustomerAName  customerName,
 br.BranchAName  BranchName,
pr.ProductADesc   ProductName,
 us.AFullName  UserName,
trf.FlowDesc, st.StatusDesc,tr.Amount,tr.TrDate
from [Transaction] tr
inner join branchs br on tr.BranchId = br.BranchId
inner join Customers c on tr.CustomerId = c.CustomerId
inner join product pr on tr.ProductId = pr.ProductId
inner join Users us on tr.UserId = us.UserId
inner join TransactionFlow trf on tr.FlowId = trf.FlowId
inner join [Status] st on tr.StatusId = st.StatusId

union

select tr.TransactionId,
 c.CustomerAName  customerName,
 br.BranchAName  BranchName,
pr.ProductADesc   ProductName,
 us.AFullName  UserName,
trf.FlowDesc, st.StatusDesc,tr.Amount,tr.TrDate
from ArchivedTransactions tr
inner join branchs br on tr.BranchId = br.BranchId
inner join Customers c on tr.CustomerId = c.CustomerId
inner join product pr on tr.ProductId = pr.ProductId
inner join Users us on tr.UserId = us.UserId
inner join TransactionFlow trf on tr.FlowId = trf.FlowId
inner join [Status] st on tr.StatusId = st.StatusId
GO
/****** Object:  Table [dbo].[ActionType]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActionType](
	[ActionTypeId] [int] IDENTITY(1,1) NOT NULL,
	[ActionTypeDesc] [varchar](max) NOT NULL,
 CONSTRAINT [PK_ActionType] PRIMARY KEY CLUSTERED 
(
	[ActionTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ArchivedDecsion]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ArchivedDecsion](
	[DecsionDate] [datetime] NOT NULL,
	[UserId] [int] NULL,
	[StatusId] [int] NULL,
	[FlowId] [int] NULL,
	[TransactionId] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CodJson]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CodJson](
	[code] [int] NULL,
	[source] [varchar](200) NULL,
	[title] [varchar](200) NULL,
	[detail] [varchar](500) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomerJason]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerJason](
	[CustomerId] [int] NOT NULL,
	[CustomerEName] [varchar](50) NULL,
	[BranchId] [int] NULL,
	[CustomerAName] [nvarchar](50) NULL,
	[DOB] [date] NULL,
	[NationalNo] [char](10) NULL,
	[Email] [varchar](50) NULL,
	[PhoneNo] [char](12) NULL,
	[Income] [decimal](15, 3) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DataLog]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataLog](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[RowId] [int] NOT NULL,
	[OldValue] [varchar](max) NULL,
	[NewValue] [varchar](max) NULL,
	[ActionDate] [datetime] NOT NULL,
	[ActionBy] [int] NOT NULL,
	[ActionTypeId] [int] NULL,
 CONSTRAINT [PK_DataLog] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Decsion]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Decsion](
	[DecsionDate] [datetime] NOT NULL,
	[UserId] [int] NULL,
	[StatusId] [int] NULL,
	[FlowId] [int] NULL,
	[TransactionId] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DeletedFlowDecsionNew]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeletedFlowDecsionNew](
	[DecsionDate] [datetime] NOT NULL,
	[UserId] [int] NULL,
	[StatusId] [int] NULL,
	[FlowId] [int] NULL,
	[TransactionId] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DeletedTransactionsNew]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeletedTransactionsNew](
	[TransactionId] [int] NOT NULL,
	[ProductId] [int] NULL,
	[CustomerId] [int] NULL,
	[BranchId] [int] NULL,
	[TrDate] [datetime] NOT NULL,
	[UserId] [int] NULL,
	[StatusId] [int] NULL,
	[Amount] [decimal](15, 3) NOT NULL,
	[FlowId] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ErrorLog]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ErrorLog](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ErrorMessage] [varchar](max) NULL,
	[ErrorLocation] [varchar](max) NOT NULL,
	[ErrorDate] [datetime] NOT NULL,
	[ErrorUser] [int] NOT NULL,
 CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Examplejson]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Examplejson](
	[Name] [varchar](100) NULL,
	[Gender] [varchar](10) NULL,
	[Homeworld] [varchar](50) NULL,
	[Born] [varchar](4) NULL,
	[Jedi] [varchar](5) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Target]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Target](
	[BranchId] [int] NULL,
	[ProductId] [int] NULL,
	[Amount] [decimal](15, 3) NOT NULL,
	[CNT] [int] NOT NULL,
	[Year] [char](4) NOT NULL,
	[IsAchived] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[testIndex]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[testIndex](
	[EmpNo] [int] NULL,
	[EmpName] [varchar](150) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [Test_Index]    Script Date: 2/5/2023 8:56:00 PM ******/
CREATE CLUSTERED INDEX [Test_Index] ON [dbo].[testIndex]
(
	[EmpNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[testIndex1]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[testIndex1](
	[EmpNo] [int] NULL,
	[EmpName] [varchar](150) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserType]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserType](
	[UserTypeId] [int] IDENTITY(1,1) NOT NULL,
	[TypeDesc] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_UserType] PRIMARY KEY CLUSTERED 
(
	[UserTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [Test_Index1]    Script Date: 2/5/2023 8:56:00 PM ******/
CREATE NONCLUSTERED INDEX [Test_Index1] ON [dbo].[testIndex1]
(
	[EmpNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Customers]  WITH CHECK ADD  CONSTRAINT [FK_Customers_Branchs] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branchs] ([BranchId])
GO
ALTER TABLE [dbo].[Customers] CHECK CONSTRAINT [FK_Customers_Branchs]
GO
ALTER TABLE [dbo].[Decsion]  WITH CHECK ADD  CONSTRAINT [FK_Decsion_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[Status] ([StatusId])
GO
ALTER TABLE [dbo].[Decsion] CHECK CONSTRAINT [FK_Decsion_Status]
GO
ALTER TABLE [dbo].[Decsion]  WITH CHECK ADD  CONSTRAINT [FK_Decsion_TransactionFlow] FOREIGN KEY([FlowId])
REFERENCES [dbo].[TransactionFlow] ([FlowId])
GO
ALTER TABLE [dbo].[Decsion] CHECK CONSTRAINT [FK_Decsion_TransactionFlow]
GO
ALTER TABLE [dbo].[Decsion]  WITH CHECK ADD  CONSTRAINT [FK_Decsion_TransactionId] FOREIGN KEY([TransactionId])
REFERENCES [dbo].[Transaction] ([TransactionId])
GO
ALTER TABLE [dbo].[Decsion] CHECK CONSTRAINT [FK_Decsion_TransactionId]
GO
ALTER TABLE [dbo].[Decsion]  WITH CHECK ADD  CONSTRAINT [FK_Decsion_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[Decsion] CHECK CONSTRAINT [FK_Decsion_Users]
GO
ALTER TABLE [dbo].[Target]  WITH CHECK ADD  CONSTRAINT [FK_Target_Branchs] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branchs] ([BranchId])
GO
ALTER TABLE [dbo].[Target] CHECK CONSTRAINT [FK_Target_Branchs]
GO
ALTER TABLE [dbo].[Target]  WITH CHECK ADD  CONSTRAINT [FK_Target_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Product] ([ProductId])
GO
ALTER TABLE [dbo].[Target] CHECK CONSTRAINT [FK_Target_Product]
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD  CONSTRAINT [FK_TransactionId_Branchs] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branchs] ([BranchId])
GO
ALTER TABLE [dbo].[Transaction] CHECK CONSTRAINT [FK_TransactionId_Branchs]
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD  CONSTRAINT [FK_TransactionId_Customers] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([CustomerId])
GO
ALTER TABLE [dbo].[Transaction] CHECK CONSTRAINT [FK_TransactionId_Customers]
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD  CONSTRAINT [FK_TransactionId_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[Product] ([ProductId])
GO
ALTER TABLE [dbo].[Transaction] CHECK CONSTRAINT [FK_TransactionId_Product]
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD  CONSTRAINT [FK_TransactionId_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[Status] ([StatusId])
GO
ALTER TABLE [dbo].[Transaction] CHECK CONSTRAINT [FK_TransactionId_Status]
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD  CONSTRAINT [FK_TransactionId_TransactionFlow] FOREIGN KEY([FlowId])
REFERENCES [dbo].[TransactionFlow] ([FlowId])
GO
ALTER TABLE [dbo].[Transaction] CHECK CONSTRAINT [FK_TransactionId_TransactionFlow]
GO
ALTER TABLE [dbo].[Transaction]  WITH CHECK ADD  CONSTRAINT [FK_TransactionId_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[Transaction] CHECK CONSTRAINT [FK_TransactionId_Users]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_Branchs] FOREIGN KEY([Branchid])
REFERENCES [dbo].[Branchs] ([BranchId])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_Branchs]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_UserType] FOREIGN KEY([UserTypeId])
REFERENCES [dbo].[UserType] ([UserTypeId])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_UserType]
GO
/****** Object:  StoredProcedure [dbo].[SP_ArchiveDecisionDataN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_ArchiveDecisionDataN]
as
begin

    begin transaction
        begin try
            
            insert into ArchivedDecsion 
            select DecsionDate, f1.UserID, f1.StatusID, f1.FlowID, f1.TransactionId
            from Decsion f1
            inner join [Transaction] tr on tr.TransactionId = f1.TransactionId
            where tr.StatusId in (2,3)
        

            delete from Decsion
            where TransactionId in (select TransactionId from [Transaction] where StatusId in (2,3))

            -- insert into Audit trail log
            insert into AuditTrailLog
            (TransactionDesc,TransactionDate,UserID)
            select 
            'Archive FlowDecision TransactionId= '+cast(TransactionId as nvarchar), GETDATE(),0
            from [Transaction]
            where StatusId in (2,3)

            commit transaction
        end try
        begin catch

            rollback transaction

            insert into ErrorLog
            (ErrorLocation,ErrorMessage,ErrorDate,ErrorUser)
            values
            (ERROR_PROCEDURE(),ERROR_MESSAGE(),GETDATE(),0)

        end catch

end
GO
/****** Object:  StoredProcedure [dbo].[SP_ArchiveTransactionDataN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure  [dbo].[SP_ArchiveTransactionDataN]
as
begin

    begin transaction
        begin try

            -- insert into data log
            insert into DataLog
            (TableName,RowID,ActionBy,ActionDate,ActionTypeId)
            select 
			'Transaction',TransactionId,
            0,GETDATE(),4
            from [Transaction]
            where StatusId in (2,3)

            insert into ArchivedTransactions
            SELECT TransactionId,Amount,BranchId,ProductId,UserId,StatusId,FlowId,CustomerId,TrDate
            FROM [Transaction]
            where StatusId in (2,3)

            delete from [Transaction]
            where StatusId in (2,3)

            -- insert into Audit trail log
            insert into AuditTrailLog
            (TransactionDesc,TransactionDate,UserID)             
            select 'Archive Transaction ID= '+cast(Transactionid as nvarchar), GETDATE(),0
            from [Transaction]
            where StatusId in (2,3)

            commit transaction
        end try
        begin catch

            rollback transaction

            insert into ErrorLog
            (ErrorLocation,ErrorMessage,ErrorDate,ErrorUser)
            values
            (ERROR_PROCEDURE(),ERROR_MESSAGE(),GETDATE(),0)

        end catch

end
GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteTransactionByTransactioId]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_DeleteTransactionByTransactioId]
@TransactionId int,
@UserId int,
@ErrorMessage varchar(max)
as
begin

begin transaction
begin try

   insert into DeletedTransactionsNew
    select * from [Transaction]
    where transactionid = @TransactionId

   insert into DeletedFlowDecsionNew
    select * from Decsion
    where TransactionId = @TransactionId

   insert into DataLog
    (TableName,RowId,ActionBy,ActionDate,ActionTypeId)
    values
    ('FlowDecision',@TransactionId,@UserId,GETDATE(),3)

   insert into DataLog
    (TableName,RowId,ActionBy,ActionDate,ActionTypeId)
    values
    ('Transactions',@TransactionId,@UserId,GETDATE(),3)

    delete from Decsion
    where TransactionId = @TransactionId

    delete from [Transaction]
    where TransactionId = @TransactionId

   insert into AuditTrailLog
    (TransactionDesc,TransactionDate,UserId)
    values
    ('Delete Transaction from transactions table with ID: '+ CAST(@TransactionId as varchar(5)),
    GETDATE(),@UserId)

   commit transaction;
   end try

begin catch
    rollback ;
    
    insert into ErrorLog
    (ErrorLocation,ErrorMessage,ErrorDate,ErrorUser)
    values
    (ERROR_PROCEDURE(),ERROR_MESSAGE(),GETDATE(),@UserId)

   set @ErrorMessage = ERROR_MESSAGE()

  end catch
  end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllTransaction]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetAllTransaction] 
@langIndector char(2)
as
begin

select tr.TransactionId,
case when @langIndector = 'AR' then c.CustomerAName when @langIndector = 'EN' then c.CustomerEName end customerName,
case when @langIndector = 'AR' then br.BranchAName when @langIndector = 'EN' then br.BranchEName end BranchName,
case when @langIndector = 'AR' then pr.ProductADesc when @langIndector = 'EN' then pr.ProductEDesc end ProductName,
case when @langIndector = 'AR' then us.AFullName when @langIndector = 'EN' then us.EFullName end UserName,
trf.FlowDesc, st.StatusDesc,tr.Amount,tr.TrDate
from [Transaction] tr
inner join branchs br on tr.BranchId = br.BranchId
inner join Customers c on tr.CustomerId = c.CustomerId
inner join product pr on tr.ProductId = pr.ProductId
inner join Users us on tr.UserId = us.UserId
inner join TransactionFlow trf on tr.FlowId = trf.FlowId
inner join [Status] st on tr.StatusId = st.StatusId
 end 
GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllTransactionByTransactionId]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAllTransactionByTransactionId] 
@langIndector char(2),
@Transactionid int 
as
begin

select tr.TransactionId,
case when @langIndector = 'AR' then c.CustomerAName when @langIndector = 'EN' then c.CustomerEName end as customerName,
case when @langIndector = 'AR' then br.BranchAName when @langIndector = 'EN' then br.BranchEName end  as BranchName,
case when @langIndector = 'AR' then pr.ProductADesc when @langIndector = 'EN' then pr.ProductEDesc end  as ProductName,
case when @langIndector = 'AR' then us.AFullName when @langIndector = 'EN' then us.EFullName end as UserName,
trf.FlowDesc, st.StatusDesc,tr.Amount,tr.TrDate
from [Transaction] tr
inner join branchs br on tr.BranchId = br.BranchId
inner join Customers c on tr.CustomerId = c.CustomerId
inner join product pr on tr.ProductId = pr.ProductId
inner join Users us on tr.UserId = us.UserId
inner join TransactionFlow trf on tr.FlowId = trf.FlowId
inner join [Status] st on tr.StatusId = st.StatusId
where tr.TransactionId = @Transactionid

 end 
GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllTransactionNew]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetAllTransactionNew]
@langIndector char(2)
as
begin

select tr.TransactionId,
case when @langIndector = 'AR' then c.CustomerAName when @langIndector = 'EN' then c.CustomerEName end customerName,
case when @langIndector = 'AR' then br.BranchAName when @langIndector = 'EN' then br.BranchEName end BranchName,
case when @langIndector = 'AR' then pr.ProductADesc when @langIndector = 'EN' then pr.ProductEDesc end ProductName,
case when @langIndector = 'AR' then us.AFullName when @langIndector = 'EN' then us.EFullName end UserName,
trf.FlowDesc, st.StatusDesc,tr.Amount,tr.TrDate
from [Transaction] tr
inner join branchs br on tr.BranchId = br.BranchId
inner join Customers c on tr.CustomerId = c.CustomerId
inner join product pr on tr.ProductId = pr.ProductId
inner join Users us on tr.UserId = us.UserId
inner join TransactionFlow trf on tr.FlowId = trf.FlowId
inner join [Status] st on tr.StatusId = st.StatusId

union 

select tr.TransactionId,
case when @langIndector = 'AR' then c.CustomerAName when @langIndector = 'EN' then c.CustomerEName end customerName,
case when @langIndector = 'AR' then br.BranchAName when @langIndector = 'EN' then br.BranchEName end BranchName,
case when @langIndector = 'AR' then pr.ProductADesc when @langIndector = 'EN' then pr.ProductEDesc end ProductName,
case when @langIndector = 'AR' then us.AFullName when @langIndector = 'EN' then us.EFullName end UserName,
trf.FlowDesc, st.StatusDesc,tr.Amount,tr.TrDate
from ArchivedTransactions tr
inner join branchs br on tr.BranchId = br.BranchId
inner join Customers c on tr.CustomerId = c.CustomerId
inner join product pr on tr.ProductId = pr.ProductId
inner join Users us on tr.UserId = us.UserId
inner join TransactionFlow trf on tr.FlowId = trf.FlowId
inner join [Status] st on tr.StatusId = st.StatusId

 end 
GO
/****** Object:  StoredProcedure [dbo].[SP_Getbestsalesprpduct]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Getbestsalesprpduct]

as
begin
   
   select p.ProductEDesc,count(*) cnt
   from Product p 
   inner join [Transaction] t on p.ProductId = t.ProductId
   where t.StatusId = 2
   group by p.ProductEDesc
   having count (*) = (select top 1 count(*) from [Transaction]       
                        where StatusId = 2 group by ProductId order by 1 desc)
						



end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetBranchApprovedLoanN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetBranchApprovedLoanN]
@LangIndicator char(2),
@BranchId int
as
begin

    select case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income,
            case when @LangIndicator = 'AR' then P.ProductADesc
                 when @LangIndicator = 'EN' then P.ProductEDesc end as ProductName,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as Employee,
            tr.Amount LoanAmount,St.StatusDesc
   from [Transaction] Tr
    inner join Customers C on Tr.CustomerId = C.CustomerId
    inner join Branchs Br on c.BranchId = Br.BranchId
    inner join Status St on Tr.StatusId = St.StatusId
    inner join Users Us on tr.UserId = Us.UserId
    inner join Product P on Tr.ProductId = p.ProductId
    where tr.StatusId = 1
    and tr.BranchId = @BranchId

end

GO
/****** Object:  StoredProcedure [dbo].[SP_GetBranchCustomersInfoN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetBranchCustomersInfoN]
@LangIndicator char(2),
@BranchId int
as
begin

        select case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income
        from Branchs Br
        inner join Customers C on C.BranchId = Br.BranchId
        where Br.BranchId = @BranchId

end

GO
/****** Object:  StoredProcedure [dbo].[SP_GetBranchPendingLoanN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetBranchPendingLoanN]
@LangIndicator char(2),
@BranchId int
as
begin

    select case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income,
            case when @LangIndicator = 'AR' then P.ProductADesc
                 when @LangIndicator = 'EN' then P.ProductEDesc end as ProductName,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as Employee,
            tr.Amount LoanAmount,St.StatusDesc
    from [Transaction] Tr
    inner join Customers C on Tr.CustomerId = C.CustomerId
    inner join Branchs Br on c.BranchId = Br.BranchId
    inner join Status St on Tr.StatusId = St.StatusId
    inner join Users Us on tr.UserId = Us.UserId
    inner join Product P on Tr.ProductId = p.ProductId
    where tr.StatusId = 1
    and Br.BranchId = @BranchId

end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetBranchRejectedLoanN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_GetBranchRejectedLoanN]
@LangIndicator char(2),
@BranchId int
as
begin

 select  case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income,
            case when @LangIndicator = 'AR' then P.ProductADesc
                 when @LangIndicator = 'EN' then P.ProductEDesc end as ProductName,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as Employee,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as RejectedBy,
            tr.Amount LoanAmount,St.StatusDesc
    from [Transaction] Tr
    inner join Customers C on Tr.CustomerId = C.CustomerId
    inner join Branchs Br on c.BranchId = Br.BranchId
    inner join Status St on Tr.StatusId = St.StatusId
    inner join Decsion FD on Tr.TransactionId = FD.TransactionId and FD.StatusId = 3
    inner join Users Us on FD.UserId = Us.UserId
    inner join Product P on Tr.ProductId = p.ProductId
    where tr.StatusId = 3
    and tr.BranchId = @BranchId

end

GO
/****** Object:  StoredProcedure [dbo].[SP_GetCustInfoApprovedLoanN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetCustInfoApprovedLoanN]
@LangIndicator char(2)
as
begin

    select case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income,
            case when @LangIndicator = 'AR' then P.ProductADesc
                 when @LangIndicator = 'EN' then P.ProductEDesc end as ProductName,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as Employee,
            tr.Amount LoanAmount,St.StatusDesc
    from [Transaction] Tr
    inner join Customers C on Tr.CustomerId = C.CustomerId
    inner join Branchs Br on c.BranchId = Br.BranchId
    inner join Status St on Tr.StatusId = St.StatusId
    inner join Users Us on Tr.UserId = Us.UserId
    inner join Product P on Tr.ProductId = p.ProductId
    where tr.StatusId = 2

end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetCustInfoPendingLoanN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetCustInfoPendingLoanN]
@LangIndicator char(2)
as
begin

    select case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income,
            case when @LangIndicator = 'AR' then P.ProductADesc
                 when @LangIndicator = 'EN' then P.ProductEDesc end as ProductName,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as Employee,
           
            tr.Amount LoanAmount,St.StatusDesc
    from [Transaction] Tr
    inner join Customers C on Tr.CustomerId = C.CustomerId
    inner join Branchs Br on c.BranchId = Br.BranchId
    inner join Status St on Tr.StatusId = St.StatusId
    inner join Users Us on tr.UserId = Us.UserId
    inner join Product P on Tr.ProductId = p.ProductId
    where tr.StatusId = 1


end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetCustInfoRejectedLoanN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetCustInfoRejectedLoanN]
@LangIndicator char(2)
as
begin
select case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income,
            case when @LangIndicator = 'AR' then P.ProductADesc
                 when @LangIndicator = 'EN' then P.ProductEDesc end as ProductName,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as Employee,
            case when @LangIndicator = 'AR' then us.AFullName
                 when @LangIndicator = 'EN' then us.EFullName end as RejectedBy,
            tr.Amount LoanAmount,St.StatusDesc
    from [Transaction] Tr
    inner join Customers C on Tr.CustomerId = C.CustomerId
    inner join Branchs Br on c.BranchId = Br.BranchId
    inner join Status St on Tr.StatusId = St.StatusId
    inner join Decsion FD on Tr.TransactionId = FD.TransactionId and FD.StatusId = 3
    inner join Users Us on FD.UserId = Us.UserId
    inner join Product P on Tr.ProductId = p.ProductId
    where tr.StatusId = 3

end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetCustomerInformationN]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[SP_GetCustomerInformationN]
@LangIndicator char(2)
as
begin

    select case when @LangIndicator = 'AR' then c.CustomerAName
                when @LangIndicator = 'EN' then c.CustomerEName end as CustomerName,
           case when @LangIndicator = 'AR' then Br.BranchAName
                when @LangIndicator = 'EN' then Br.BranchEName end as BranchName,
            Email,PhoneNo,NationalNo,DOB,Income
    from Customers C
    inner join Branchs Br on c.BranchId = Br.BranchId

end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetGabToAchive]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_GetGabToAchive]

as
begin
select tbl.BranchEName,tbl.ProductEDesc, 
case when tbl.TargetAmt < = tbl.AMT then 0 else tbl.TargetAmt- tbl.AMT end AmountGAP,
case when tbl.TargetCNT < = tbl.CNT then 0 else tbl.TargetCNT - tbl.CNT end CountGAP

from 
(
select b.branchename, p.ProductEDesc, sum (amount) AMT, Count (*) CNT, 
(select sum(amount) from 
target where branchid = t.branchid and productid = t.productid and [Year] = Year(Getdate())) TargetAmt,
( select cnt from 
 target where branchid = t.branchid and ProductId = t.productid and [Year] = Year(Getdate())) TargetCNT
from [transaction] t 
inner join branchs b on t.BranchId = b.BranchId
inner join product p on t.ProductId = p.ProductId
where StatusId = 2
group by b.BranchEName,p.ProductEDesc,t.BranchId,t.ProductId) tbl

end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetHighestBranchSales]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetHighestBranchSales]
 as
begin
   
   select b.BranchEName,count(*) cnt
   from 
    [Transaction] t
	inner join branchs b on t.BranchId = b.BranchId
   where t.StatusId = 2
   group by  b.BranchEName
   having count (*) in  (select top 2 count(*) from [Transaction]       
                        where StatusId = 2 group by BranchId order by 1 desc)
						
end
GO
/****** Object:  StoredProcedure [dbo].[SP_GETTheAchivment]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GETTheAchivment]
as 
begin 
select tbl.BranchEName,tbl.ProductEDesc,
case when tbl.TargetAmt < = tbl.AMT then 'Amount Achived' else 'Amount Not Achived' end AmountAchivment,
case when tbl.TargetCNT < = tbl.CNT then 'Count Achived' else 'Count Not Achived' end CountAchivment

from 
(
select b.branchename, p.ProductEDesc, sum (amount) AMT, Count (*) CNT, 
(select sum(amount) from 
target where branchid = t.branchid and productid = t.productid and [Year] = Year(Getdate())) TargetAmt,
( select cnt from 
 target where branchid = t.branchid and ProductId = t.productid and [Year] = Year(Getdate())) TargetCNT
from [transaction] t 
inner join branchs b on t.BranchId = b.BranchId
inner join product p on t.ProductId = p.ProductId
where StatusId = 2
group by b.BranchEName,p.ProductEDesc,t.BranchId,t.ProductId) tbl

end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetTransactionDesion]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetTransactionDesion]
 @transactionid int 
 as 
 begin 
 select  c.CustomerEName,tr.Amount,isnull(tf.flowdesc,tf1.FlowDesc) department,
 isnull(st.statusdesc,st1.StatusDesc) status,
 isnull(us.Efullname,us1.Efullname) username,isnull(fd.DecsionDate,tr.TrDate) Trdate
 from [Transaction] tr 
 left join Decsion fd on tr.TransactionId = fd.TransactionId
 left join Status st on fd.StatusId = st.StatusId
 left join Status st1 on st1.StatusId = tr.StatusId
 left join TransactionFlow tf on tf.FlowId = fd.FlowId
 left join TransactionFlow tf1 on tf1.FlowId =tr.FlowId
 left join Users us on us.UserId = fd.UserId
 left join Users us1 on us.UserId = fd.UserId
 left join Customers c on tr.CustomerId = c.CustomerId
 where tr.TransactionId = @Transactionid
end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertCodejsonByJSON]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_InsertCodejsonByJSON]
@json nvarchar(max),
@UserId int,
@ErrorMessage varchar(max) out

as
begin
begin transaction
begin try

insert into codjson
(code,source ,title ,detail ) 
select code,source ,title ,detail
from openjson(@json) 
with (code int,
	source varchar(200),
	title varchar(200),
	detail varchar(500)
	)

 
     commit transaction;
     end try

     begin catch
     rollback;

     insert into ErrorLog (ErrorMessage,errordate,errorlocation,erroruser)
     values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)
     select @ErrorMessage = ERROR_MESSAGE();

    end catch
    end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertCustomerByJSON]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_InsertCustomerByJSON]
@json nvarchar(max),
@UserId int,
@ErrorMessage varchar(max) out

as
begin
begin transaction
begin try

insert into CustomerJason
(CustomerId, CustomerEName, BranchId, CustomerAName, DOB, NationalNo, Email, PhoneNo, Income) 
select CustomerId, CustomerEName, BranchId, CustomerAName, cast(DOB as date), NationalNo, Email, PhoneNo, Income
from openjson(@json) -- from table customer json by open it openjson by @json
with (CustomerId int, CustomerEName varchar (200),BranchId int, CustomerAName nvarchar (200), DOB varchar (50), 
NationalNo varchar(50) ,Email varchar (100),
PhoneNo nvarchar(100),Income Decimal(15,3))
-- with header and data type,should set int still as int and decimal still as decimal but any else should be as nvarchar and varchar with bigger
-- char (200) or (100)
 
     commit transaction;
     end try

     begin catch
     rollback;

     insert into ErrorLog (ErrorMessage,errordate,errorlocation,erroruser)
     values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)
     select @ErrorMessage = ERROR_MESSAGE();

    end catch
    end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertExamplejsonByJSON]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_InsertExamplejsonByJSON]
@json nvarchar(max),
@UserId int,
@ErrorMessage varchar(max) out

as
begin
begin transaction
begin try

insert into Examplejson
(Name ,Gender ,Homeworld ,Born ,Jedi ) 
select Name ,Gender ,Homeworld ,year(getdate()) - substring (born,0,charindex('B',born,1)),Jedi 
from openjson(@json) 
with (Name varchar(100),
	Gender varchar (10),
	Homeworld varchar(50),
	Born varchar(4),
	Jedi varchar(5)
	)

 
     commit transaction;
     end try

     begin catch
     rollback;

     insert into ErrorLog (ErrorMessage,errordate,errorlocation,erroruser)
     values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)
     select @ErrorMessage = ERROR_MESSAGE();

    end catch
    end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewCusotmer]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_InsertNewCusotmer]
@AName nvarchar(50),
@EName varchar(50),
@Email varchar(50),
@PhoneNo char(12),
@BranchId int,
@DOB date,
@NationalNo char(10),
@Income decimal(15,3),
@UserId int,
@ErrorMessage varchar(max) out
as
begin
begin transaction
begin try

    insert into Customers(CustomerAName,CustomerEName,Email,PhoneNo,DOB,NationalNo,Income,BranchId)
                   values(@AName,@EName,@Email,@PhoneNo,@DOB,@NationalNo,@Income,@BranchId)

    insert into DataLog(TableName,RowId,OldValue,NewValue,ActionDate,ActionTypeId,ActionBy)
           values('Customers',IDENT_CURRENT('Customers'),'','ArName: '+@AName+' ,EnName: '+@EName+' ,
		   Email: '+@Email+' ,PhoneNumber: '+@PhoneNo+' ,DOB:'+cast(@DOB as varchar(100)) +' ,
		   NationalNo: '+@NationalNo+' ,Income: '+cast(@Income as varchar(15))+', Branchid:'+cast(@Branchid as varchar(5)),GETDATE(),1,@UserId)

    insert into AuditTrailLog (TransactionDesc,TransactionDate,UserId)
    values ('Insert new customer with Id:' +cast (IDENT_CURRENT('customers')as varchar (5)),GETDATE(),@UserId)

	 commit transaction;
	 end try

	 begin catch
	 rollback;

	 insert into ErrorLog (errormessage,errordate,errorlocation,erroruser)
	 values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)
	 select @ErrorMessage = ERROR_MESSAGE();

	end catch
    end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewTransaction]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_InsertNewTransaction]

@BranchId int,
@CustomerId int,
@ProductId int,
@Amount decimal(15,3),
@UserId int,
@ErrorMessage varchar(max) out

As 
Begin 
Begin transaction 
Begin Try
-- لازم اعرف متغير داخلي مكان ال
-- flowid = @trflow 
-- ممكن اعطي قيمة لمتغير عن طريق 
-- declare @trflow int
declare @Trflow int 
select top 1 @Trflow = FlowId
from TransactionFlow
order by FlowOrder

     Insert Into [Transaction] (Amount,BranchId,ProductId,UserId,StatusId,FlowId,CustomerId,TrDate)
	 Values ( @Amount,@BranchId,@ProductId,@UserId,1,@Trflow,@CustomerId,Getdate())

	 Insert Into AuditTrailLog (TransactionDesc,TransactionDate,UserId)
	Values ('Create New Transaction with Id:'+ cast(IDENT_CURRENT('Transaction') as varchar(5)),GETDATE(),@UserId)

	 Insert Into DataLog (TableName,RowId,OldValue,NewValue,ActionDate,ActionTypeId,ActionBy)
	 Values ('Transaction',IDENT_CURRENT('Transaction'),'','Branchid:' +cast (@BranchId as varchar(5))+',
	          ProductId:' +cast(@productid as varchar(5)) +',UserId:'+cast(@UserId as varchar(5))+',
			  Amount:'+cast(@amount as varchar (15))+', CustomerId:'+ cast (@CustomerId as varchar(5))+',
			,StatusId: 1 ,trflow:'+cast(@Trflow as varchar(5)), GETDATE(),1,@UserId)

select * from [transaction]
Commit Transaction 
End Try 
Begin Catch 
Rollback
 
	 Insert Into ErrorLog  (errormessage,errordate,errorlocation,erroruser)
	 Values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)
	 Select @ErrorMessage = ERROR_MESSAGE();

End Catch
End
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewUser]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_InsertNewUser]
@EFullName varchar(500),
@AFullName nvarchar(500),
@UserName varchar(50),
@Password varchar(50),
@BranchId int,
@UserTypeId int,
@EmployeeId int,
@UserId int,
@ErrorMessage varchar(max) out
as
begin
begin transaction
begin try

    insert into Users(Username,UserTypeId,[Password],EFullName,AFullName,IsActive,Employeeid,branchid)
                   values(@Username,@UserTypeId,@Password,@EFullName,@AFullName,1,@Employeeid,@BranchId)

    insert into DataLog(TableName,RowId,OldValue,NewValue,ActionDate,ActionTypeId,ActionBy)
           values('Users',IDENT_CURRENT('Users'),'','EFullName: '+@EFullName+',AFullName:'+@AFullName+',
		   UserName: '+@Username+'  ,Password: '+@Password+' ,branchid: '+cast(@branchid as varchar(5))+',
		   UserTypeId: '+cast(@UserTypeId as varchar(5))+',EmplyeeId:'+cast(@Employeeid as varchar(5)),GETDATE(),1,@UserId)

    insert into AuditTrailLog (TransactionDesc,TransactionDate,UserId)
    values ('Insert new User with Id:' + cast(IDENT_CURRENT('Users') as varchar(5)),GETDATE(),@UserId)

	 commit transaction;
	 end try

	 begin catch
	 rollback;

	 insert into ErrorLog (errormessage,errordate,errorlocation,erroruser)
	 values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)
	 select @ErrorMessage = ERROR_MESSAGE();

	end catch
    end
GO
/****** Object:  StoredProcedure [dbo].[SP_ReturnTransactionFromDeleted]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_ReturnTransactionFromDeleted]
@TransactionId int,
@UserId int,
@ErrorMessage varchar(max)
as
begin

begin transaction
begin try

--1
 insert into DataLog
    (TableName,RowId,ActionBy,ActionDate,ActionTypeId)
    values
    ('DeletedTransactionsNew',@TransactionId,@UserId,GETDATE(),5)

	 
--2
SET identity_insert [Transaction] ON
    insert into [Transaction] (TransactionId,CustomerId,BranchId,Amount,ProductId,StatusId,TrDate,FlowId,UserId)
    select TransactionId,CustomerId,BranchId,Amount,ProductId,StatusId,TrDate,FlowId,UserId from DeletedTransactionsNew
    where transactionid = @TransactionId
SET identity_insert [Transaction] OFF


  insert into Decsion (TransactionId,FlowId,DecsionDate,StatusId,UserId)
  select TransactionId,FlowId,DecsionDate,StatusId,UserId from DeletedFlowDecsionNew
  where TransactionId = @TransactionId
  



    

	delete from DeletedTransactionsNew
    where TransactionId = @TransactionId

	delete from DeletedFlowDecsionNew
    where TransactionId = @TransactionId


   insert into AuditTrailLog
    (TransactionDesc,TransactionDate,UserId)
    values
    ('Retrive Transaction data with ID: '+ CAST(@TransactionId as varchar(5)), GETDATE(),@UserId)
   commit transaction;
   end try

   begin catch
    rollback ;
    
    insert into ErrorLog
    (ErrorLocation,ErrorMessage,ErrorDate,ErrorUser)
    values
    (ERROR_PROCEDURE(),ERROR_MESSAGE(),GETDATE(),@UserId)

   set @ErrorMessage = ERROR_MESSAGE()

  end catch
  end
GO
/****** Object:  StoredProcedure [dbo].[SP_TransactionFlowDecsion]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_TransactionFlowDecsion]
@StatusId int,
@UserId int,
@TransactionId int,
@ErrorMessage varchar(max) out
as
begin

begin transaction
begin try
    declare @NextStep int,
            @CurrentStep int,
            @CurrentStepDesc varchar(100),
            @LastStep int,
			@amountstep decimal( 15,3)

			
			select @amountstep = Amount
			from [Target] 
			where Amount > = (
			select amount from [Transaction]
			where TransactionId = @TransactionId)



   select  top 1 @nextStep = FlowId
 from TransactionFlow
  where FlowOrder > (
             select FlowOrder
             from TransactionFlow
             where FlowId = ( select FlowId from [Transaction] where TransactionId = @TransactionId)) 
  and IsActive = 1
  order by FlowOrder 


   select @CurrentStep = flowid  from [Transaction] where TransactionId = @TransactionId

   select @CurrentStepDesc = FlowDesc
   from TransactionFlow
   where FlowId = ( select FlowId from [Transaction] where TransactionId = @TransactionId) 
    
   select @LastStep = FlowId
   from TransactionFlow
   where FlowOrder = (select max(FlowOrder) from TransactionFlow)



      if @StatusId = 2 and @NextStep <> @LastStep
      begin

       insert into Decsion
        (FlowId,StatusId,UserId,TransactionId,DecsionDate)
        values
        (@CurrentStep,@StatusId,@UserId,@TransactionId,GETDATE())



       insert into DataLog
        (TableName,RowId,OldValue,NewValue,ActionBy,ActionDate,ActionTypeId)
        values
        ('Transactions',@TransactionId,'TrFlow: '+cast(@CurrentStep as varchar(5)),
        'TrFlow: '+cast(@NextStep as varchar(5)),@UserId,GETDATE(),2)



        update [Transaction]
        set FlowId = @NextStep
        where TransactionId = @TransactionId



        insert into AuditTrailLog
        (TransactionDesc,TransactionDate,UserId)
        Values
        ('The transaction with ID: '+cast(@TransactionId as varchar(5))+' has been approved by '+@CurrentStepDesc,
          GETDATE(),@UserId)



   end
    else if @StatusId = 2 and @NextStep = @LastStep
    begin
        insert into Decsion
        (FlowId,StatusId,UserId,TransactionId,DecsionDate)
        values
        (@CurrentStep,@StatusId,@UserId,@TransactionId,GETDATE())

		select * from [Target]

       insert into DataLog
        (TableName,RowId,OldValue,NewValue,ActionBy,ActionDate,ActionTypeId)
       select 'Transactions',@TransactionId,'TrFlow: '+cast(@CurrentStep as varchar(5))+',Status: '+cast(StatusId as varchar(5)),
        'TrFlow: '+cast(@NextStep as varchar(5))+',Status: '+cast(@StatusId as varchar(5)),@UserId,GETDATE(),2
		from [Transaction]
		  where TransactionId = @TransactionId



       update [Transaction]
        set FlowId = @NextStep,
            StatusId = @StatusId
        where TransactionId = @TransactionId


       insert into AuditTrailLog
        (TransactionDesc,TransactionDate,UserId)
        Values
        ('The transaction with ID: '+cast(@TransactionId as varchar(5))+' has been approved by '+@CurrentStepDesc,
        GETDATE(),@UserId)

   update target
   set IsAchived = dbo.FN_IsAchivedTarget(@transactionid)
   where Branchid = (select BranchId from [Transaction] where TransactionId = @TransactionId)
   and Productid = (select ProductId from [Transaction] where TransactionId = @TransactionId)
   
   end 
    else if @StatusId = 3
    begin
        insert into Decsion
        (FlowId,StatusId,UserId,TransactionId,DecsionDate)
        values
        (@CurrentStep,@StatusId,@UserId,@TransactionId,GETDATE())

       insert into DataLog
        (TableName,RowId,OldValue,NewValue,ActionBy,ActionDate,ActionTypeId)
        select 'Transactions',@TransactionId,'Status: '+cast(StatusId as varchar(5)),
        'Status: '+cast(@StatusId as varchar(5)),@UserId,GETDATE(),2
        from [Transaction]
        where TransactionId = @TransactionId

       update [Transaction]
        set StatusId = @StatusId
        where Transactionid = @TransactionId

       insert into AuditTrailLog
        (TransactionDesc,TransactionDate,UserId)
        Values
        ('The transaction with ID: '+cast(@TransactionId as varchar(5))+' has been rejected by '+@CurrentStepDesc,
        GETDATE(),@UserId)
    end

   commit transaction;
   end try
   begin catch
    
    rollback ;
    
    insert into ErrorLog
    (ErrorLocation,ErrorMessage,ErrorDate,ErrorUser)
    values
    (ERROR_PROCEDURE(),ERROR_MESSAGE(),GETDATE(),@UserId)

   set @ErrorMessage = ERROR_MESSAGE()
   end catch
   end
GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateCustomer]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_UpdateCustomer]
@CustomerId int ,
@Email varchar(50) ,
@BranchId int ,
@PhoneNo char(10) ,
@Income decimal(15,3),
@UserId int,
@ErrorMessage varchar(max) out

as
begin
begin transaction
begin try

insert into DataLog(TableName,RowId,OldValue,NewValue,ActionDate,ActionTypeId,ActionBy)
     select'Customers',@CustomerId,'Email: '+Email+' ,PhoneNo: '+PhoneNo +', BranchId: '+cast(BranchId as varchar(5))+'
      , Income: '+cast(Income as varchar(15)),
         'Email: '+@Email+' ,PhoneNo: '+@PhoneNo +
         ',   BranchId: '+cast(@BranchId as varchar(5))+
         ',   Income: '+cast(@Income as varchar(15)),GETDATE(),2, @UserId                        
      from Customers
       where CustomerId = @CustomerId

Update Customers
set phoneNo= @PhoneNo,
    Email= @Email,
    Income= @Income,
    BranchId= @BranchId
    where CustomerId = @CustomerId

 insert into AuditTrailLog (TransactionDesc,TransactionDate,UserId)
 values ('Update customer with Id:' +cast(@CustomerId as varchar(5)),GETDATE(),@UserId)
   commit transaction;  
   end try

   begin catch 
   rollback;

  insert into ErrorLog (errormessage,errordate,errorlocation,erroruser) 
  values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)   
  set @errormessage = ERROR_MESSAGE();
   end catch
   end
GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateTransaction]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_UpdateTransaction]

@TransactionId int,
@BranchId int,
@StatusId int,
@FlowId int,
@TrDate datetime,
@UserId int,
@ErrorMessage varchar(max) out
as
begin
begin transaction
begin try

insert into DataLog(TableName,RowId,OldValue,NewValue,ActionDate,ActionTypeId,ActionBy)
     select 'Transaction',@transactionid,'BranchId:' +cast(BranchId as varchar(5))+',StatusId:'+cast(statusid as varchar (5))+',FlowId:'
	 +cast(flowid as varchar(5))+',TrDate:'+cast(TrDate as char(15)),'BranchId:' +cast(@BranchId as varchar(5))+',StatusId:'+
	 cast(@StatusId as varchar (5))+',FlowId:'+cast(@FlowId as varchar(5))+',TrDate:'+cast(Getdate() as char(15)),GETDATE(),2, @UserId                        
      from [Transaction]
       where TransactionId =@TransactionId

Update [Transaction]
set branchid= @BranchId,
    StatusId= @StatusId,
	FlowId = @FlowId,
	Trdate = getdate()
     where TransactionId = @TransactionId

 insert into AuditTrailLog (TransactionDesc,TransactionDate,UserId)
 values ('Update Transaction with Id:' +cast(@TransactionId as varchar(5)),GETDATE(),@UserId)
   commit transaction;  
   end try

   begin catch 
   rollback;

  insert into ErrorLog (errormessage,errordate,errorlocation,erroruser) 
  values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)   
  set @errormessage = ERROR_MESSAGE();
   end catch
   end
GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateUsers]    Script Date: 2/5/2023 8:56:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateUsers]
@BranchId int,
@UserTypeId int,
@UserId int,
@ErrorMessage varchar(max) out 

as
begin
begin transaction
begin try

insert into DataLog(TableName,RowId,OldValue,NewValue,ActionDate,ActionTypeId,ActionBy)
     select'Users',@UserId,'Branchid: '+BranchId+' ,UserTypeId: '+cast(UserTypeId as varchar(5)),'Branchid: '+cast(@BranchId as varchar(5))+' ,
	 UserTypeId: '+cast(@UserTypeId as varchar(5)),GETDATE(),2, @UserId                        
      from Users
       where UserId = @UserId

Update Users
set branchid= @BranchId,
    
    UserTypeId= @UserTypeId
    where UserId = @UserId

 insert into AuditTrailLog (TransactionDesc,TransactionDate,UserId)
 values ('Update users with Id:' +cast(@UserId as varchar(5)),GETDATE(),@UserId)
   commit transaction;  
   end try

   begin catch 
   rollback;

  insert into ErrorLog (errormessage,errordate,errorlocation,erroruser) 
  values ( ERROR_MESSAGE(),GETDATE(),ERROR_PROCEDURE(),@userid)   
  set @errormessage = ERROR_MESSAGE();
   end catch
   end
GO
USE [master]
GO
ALTER DATABASE [BranchSales2022] SET  READ_WRITE 
GO
