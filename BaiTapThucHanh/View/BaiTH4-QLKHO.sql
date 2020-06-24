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



/* 2. thống kê tiền bán theo mã vật tư gồm 
MaVT, TênVT, TienBan (TienBan=SoLuongX*DonGiaX) */
create view TienBanVatTu as
select Ton.MaVT, TenVT, SUM(SoLuongX*DonGiaX) as N'Tiền bán'
from Ton inner join Xuat on Ton.MaVT=Xuat.MaVT
group by Ton.MaVT, TenVT
go
--test
select * from TienBanVatTu
go

/* 3. thống kê soluongxuat theo tên vattu */
create view VatTuDaXuat as
select TenVT, SUM(SoLuongX) as N'SL Xuất'
from Ton inner join Xuat on Ton.MaVT=Xuat.MaVT
group by TenVT
go
--test
select * from VatTuDaXuat
go

/* 4. thống kê soluongnhap theo tên vật tư */
create view VatTuDaNhap as
select TenVT, SUM(SoLuongN) as N'SL Nhập'
from Ton inner join Nhap on Ton.MaVT=Nhap.MaVT
group by TenVT
go
--test
select * from VatTuDaNhap
go

/* 5. đưa ra tổng soluong còn trong kho 
biết còn = nhap – xuất + tồn theo từng nhóm vật tư */
create view SLVatTuCon as
select Ton.MaVT, TenVT, SUM(SoLuongN)-SUM(SoLuongX)+SUM(SoLuongT) as 'SoLuongCon'
from Ton inner join Nhap on Ton.MaVT=Nhap.MaVT
		 inner join Xuat on Ton.MaVT=Xuat.MaVT
group by Ton.MaVT, TenVT
go
--test
select * from SLVatTuCon
go


/* 6. đưa ra tên vật tư  số lượng tồn nhiều nhất */
create view SLTonMax as
select TenVT from Ton 
where SoLuongT = (select MAX(SoLuongT) from Ton)
go
-- test
select * from SLTonMax
go



/* 7. đưa ra các vật tư có tổng số lượng xuất lớn hơn 100 */
create view SLXuat100 as
select Ton.MaVT,TenVT
from Ton inner join Xuat on Ton.MaVT=Xuat.MaVT
group by Ton.MaVT,TenVT having SUM(SoLuongX) > 100

go
--test
select * from SLXuat100
go



/* 8. Tạo view đưa ra tháng xuất,
năm xuất, tổng số lượng xuất 
thống kê theo tháng và năm xuất */
create view NgayXuat as
select MONTH(NgayX) as N'Tháng', YEAR(NgayX) as N'Năm', SUM(SoLuongX) as N'Tổng số lượng xuất'
from Xuat
group by MONTH(NgayX), YEAR(NgayX)

go
--test
select * from NgayXuat
go



/* 9. tạo view đưa ra mã vật tư. tên vật tư. 
số lượng nhập. số lượng xuất. đơn giá N. 
đơn giá X. ngày nhập. Ngày xuất */
create view ShowNhapXuat as
select Ton.MaVT, TenVT, SoLuongN, SoLuongX, DonGiaN, DonGiaX, NgayN, NgayX
from Ton inner join Nhap on Ton.MaVT=Nhap.MaVT
		 inner join Xuat on Ton.MaVT=Xuat.MaVT

go
--test
select * from ShowNhapXuat
go


/* 10. Tạo view đưa ra mã vật tư. 
tên vật tư và tổng số lượng còn lại trong kho. 
biết còn lại = SoluongN-SoLuongX+SoLuongT
theo từng loại Vật tư  trong năm 2015 */

create view SLVatTuCon2015 as
select Ton.MaVT, TenVT, SUM(SoLuongN)-SUM(SoLuongX)+SUM(SoLuongT) as 'SoLuongCon'
from Ton inner join Nhap on Ton.MaVT=Nhap.MaVT
		 inner join Xuat on Ton.MaVT=Xuat.MaVT
where YEAR(NgayN)=2015 and YEAR(NgayX)=2015
group by Ton.MaVT, TenVT
go
--test
select * from SLVatTuCon2015
go