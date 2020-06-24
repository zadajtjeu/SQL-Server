use master
go
if(exists(select * from sysdatabases where name='QLBenhVien'))
	drop database QLBenhVien
go

/* Câu 1 */
--create database
use master
go
create database QLBenhVien
go

use QLBenhVien
go

--create table
create table DV(
	MaDV nvarchar(10) not null primary key,
	TenDV nvarchar(50),
	gia money default 0 check(gia>0)
)
create table BenhNhan(
	MaBN nvarchar(10) not null primary key,
	HoTen nvarchar(50),
	NgaySinh date,
	GioiTinh bit
)
create table PhieuKham(
	SoPhieu nvarchar(10) not null,
	MaDV nvarchar(10) not null references DV(MaDV),
	MaBN nvarchar(10) not null references BenhNhan(MaBN),
	ngay date,
	sl int default 0,
	constraint pk_PhieuKham primary key(SoPhieu, MaDV)
)
go

--insert data
insert into DV values('DV1', N'Tai Mũi Họng', 200000),
					 ('DV2', N'Răng Hàm Mặt', 2000000)
insert into BenhNhan values('BN1', N'Ngô Phan Úy', '12/22/1996', 0),
							('BN2', N'Đại Hà Lan', '07/09/1998', 1),
							('BN3', N'Cù Trongh Xoay', '05/01/1990', 0),
							('BN4', N'Đại Gia Phát', '09/19/2000', 0),
							('BN5', N'Lê Lý Thị Lan', '06/11/1992', 1),
							('BN6', N'Huỳnh Ngô Tú', '10/28/1995', 0),
							('BN7', N'Trần Mai Thúy', '09/07/1997', 1)
insert into PhieuKham values('PK1', 'DV1', 'BN2', '06/23/2020', 2),
							('PK1', 'DV2', 'BN2', '06/24/2020', 3)
go

--test
select * from DV
select * from BenhNhan
select * from PhieuKham
go













/*                              *
 *============ DE 11 ============*
 *                              */









/* Cau 2: view */

create view TKBenhNhan as
select Ngay as N'Ngày',
case GioiTinh when 0 then N'Nam' when 1 then N'Nữ' end as N'Giới Tính',
COUNT(*) as N'Số_người'
from BenhNhan inner join PhieuKham on PhieuKham.MaBN=BenhNhan.MaBN
where GioiTinh=1
group by Ngay, GioiTinh
go

--test
select * from TKBenhNhan
go


/* Câu 3: store procedure */
create proc TongTien(@Ngay date) as
begin
	select SUM(sl*gia) from PhieuKham
	inner join DV on DV.MaDV=PhieuKham.MaDV
	where ngay=@Ngay
end

go

--test
exec TongTien '06/23/2020'
go


/* Cau 4: trigger */
create trigger trg_insertPhieuKham on PhieuKham for insert as
begin
	declare @day date = (select ngay from inserted)
	if(DAY(@day) <> DAY(getdate())
		OR MONTH(@day) <> MONTH(getdate())
		OR YEAR(@day) <> YEAR(getdate()))
	begin
		raiserror(N'Ngày nhập phải là ngày hiện tại',16,1)
		rollback tran
		return
	end
end
go

--test
insert into PhieuKham values('PK2', 'DV2', 'BN3', getdate(), 2)
insert into PhieuKham values('PK3', 'DV1', 'BN4', '06/24/2020', 3) --do hôm t làm là 24/6 nên TH này nó đúng nhé
--loi
insert into PhieuKham values('PK3', 'DV2', 'BN4', '06/23/2020', 3)
select * from PhieuKham
go











/*                              *
 *============ DE 14 ============*
 *                              */










/* Câu 2: view */
create view BenhNhanTuoiCao as
select MaBN, HoTen, YEAR(getdate())-YEAR(NgaySinh) as N'Tuổi'
from BenhNhan
where YEAR(getdate())-YEAR(NgaySinh) = (select MAX(YEAR(getdate())-YEAR(NgaySinh)) from BenhNhan)
go

--test
select * from BenhNhanTuoiCao
go


/* Câu 3: function */

create function TimBenhNhan(@mabn nvarchar(10))
returns @infor table(MaBN nvarchar(10), HoTen nvarchar(50), 
					NgaySinh date, GioiTinh nvarchar(5))
as
begin
	insert into @infor
		select MaBN, HoTen, NgaySinh,
			case GioiTinh when 0 then N'Nam' when 1 then N'Nữ' end
		from BenhNhan where MaBN=@mabn
	return
end

go

--test
select * from TimBenhNhan('BN1')
go


/* Câu 4: trigger */
create trigger trg_insertBN on BenhNhan for insert as
begin
	declare @ngay date = (select NgaySinh from inserted)

	if(@ngay > getdate())
	begin
		raiserror(N'Ngày sinh nhập không chính xác',16,1)
		rollback tran
		return
	end
end
go

--test
insert into BenhNhan values('BN9', N'Hà Trọng Nghĩa', '12/22/1996', 0)
--loi
--insert into BenhNhan values('BN10', N'ABC', '12/22/2050', 0)
select * from BenhNhan
go