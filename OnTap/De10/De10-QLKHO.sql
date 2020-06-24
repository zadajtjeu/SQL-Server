use master
go
if(exists(select * from sysdatabases where name='QLKHO'))
	drop database QLKHO
go

/* 1. create database
	Nhap (SoHDN,MaVT,SoLuongN,DonGiaN,NgayN)
	Xuat (SoHDX,MaVT,SoLuongX,DonGiaX,NgayX)
	Ton (MaVT,TenVT,SoLuongT)
Xây dựng mô hình quan hệ cho 3 bảng trên,
	 ở bảng nhập hãy nhập 3 phiếu nhập, 
	 ở  bảng xuất nhập 2 phiếu xuất, 
	 bảng Ton  nhập 5 vật tư khác nhau.
 */

use master
go
create database QLKHO
go

-- create table
use QLKHO
go

create table Ton(
	MaVT nvarchar(10) not null primary key,
	TenVT Nvarchar(30) not null,
	SoLuongT int default 0
)

create table Nhap(
	SoHDN nvarchar(10) not null,
	MaVT nvarchar(10) not null,
	SoLuongN int not null,
	DonGiaN money default 0,
	NgayN DateTime,
	constraint Nhap_Ton foreign key(MaVT) references Ton(MaVT),
	constraint Nhap_Pri_Key Primary Key(SoHDN, MaVT)
)

create table Xuat(
	SoHDX nvarchar(10) not null,
	MaVT nvarchar(10) not null,
	SoLuongX int not null,
	DonGiaX money default 0,
	NgayX DateTime,
	constraint Xuat_Ton foreign key(MaVT) references Ton(MaVT),
	constraint Xuat_Pri_Key Primary Key(SoHDX, MaVT)
)

go


-- insert data
insert into Ton
values ('VT0001',N'Ống đồng',100),
		('VT0002',N'Ống thép D6',0),
		('VT0003',N'Ống thép D8',200),
		('VT0004',N'Thép lá',50),
		('VT0005',N'Thép U',90)
go

-- insert Nhap-Xuat
insert into Nhap
values('HDN0001','VT0001', 380, 50000, '1/20/2015'),
		('HDN0001','VT0004', 100, 18000, '1/20/2015'),
		('HDN0002','VT0005', 150, 30000, '2/1/2015'),
		('HDN0003','VT0003', 500, 85000, '3/22/2016'),
		('HDN0003','VT0001', 200, 52000, '3/22/2016')
insert into Xuat
values('HDX0001','VT0001', 10, 55000, '4/3/2015'),
		('HDX0001','VT0005', 52, 22000, '4/3/2015'),
		('HDX0002','VT0001', 50, 56000, '5/12/2020'),
		('HDX0002','VT0003', 150, 35000, '5/12/2020')
go
-- test
select * from Nhap
select * from Xuat
select * from Ton
go

/* Câu 2 */
/* 2. thống kê tiền bán theo mã vật tư gồm 
MaVT, TenVT, TienBan (TienBan=SoLuongX*DonGiaX) */
create view TienBanVatTu as
select Ton.MaVT, TenVT, SUM(SoLuongX*DonGiaX) as TienBan
from Ton inner join Xuat on Ton.MaVT=Xuat.MaVT
group by Ton.MaVT, TenVT
go
--test
select * from TienBanVatTu
go



/* Cau 3: function */
create function TKTienBan(@mavt nvarchar(10))
returns @thongke table(MaVT nvarchar(10), TenVT nvarchar(50), TienBan money)
as
begin
	insert into @thongke
		select Ton.MaVT, TenVT, SUM(SoLuongX*DonGiaX) as TienBan
		from Ton inner join Xuat on Ton.MaVT=Xuat.MaVT 
		where Ton.MaVT=@mavt
		group by Ton.MaVT, TenVT
	return
end
go
--test
select * from TKTienBan('VT0001')
go

/* Câu 4: */
create proc TKTienDong(@mavt nvarchar(10), @tiendong money output)
as
begin
	set @tiendong =
	(select SoLuongT*MAX(DonGiaN) from Ton
	inner join Nhap on Nhap.MaVT=Ton.MaVT
	where Ton.MaVT=@mavt
	group by SoLuongT,Nhap.MaVT)
end

go

--test
declare @tien money
exec TKTienDong 'VT0001', @tien output
select N'Tiền đọng của vật tư VT0001 là '=@tien
go