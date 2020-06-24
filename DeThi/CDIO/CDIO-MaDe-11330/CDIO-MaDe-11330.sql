use master
if(exists(select * from sysdatabases where name='QLBanHang'))
	drop database QLBanHang
go

/* Cau 1: */
use master
create database QLBanHang

go

use QLBanHang

go
--a.create table
create table VatTu(
	MaVT nvarchar(10) not null primary key,
	TenVT nvarchar(50),
	DVTinh nvarchar(20),
	SLCon int default 0
)
create table HoaDon(
	MaHD nvarchar(10) not null primary key,
	NgayLap date,
	HoTenKhach nvarchar(50)
)

create table CTHoaDon(
	MaHD nvarchar(10) not null,
	MaVT nvarchar(10) not null,
	DonGiaBan money default 0,
	SLBan int default 0,
	constraint VT_CTHD foreign key(MaVT) references VatTu(MaVT),
	constraint HD_CTHD foreign key(MaHD) references HoaDon(MaHD),
	constraint fk_CTHD primary key(MaHD, MaVT)
)

go

--b. insert data
insert into VatTu values('VT01', N'Xi măng Thăng Long', N'Bao 50kg', 200),
						('VT02', N'Xi măng trắng', N'Bao 50kg', 350),
						('VT03', N'Cát vàng', N'Khối', 100)
insert into HoaDon values('HD01', '4/22/2020', N'Phạm Thanh Nam'),
						 ('HD02', '4/12/2020', N'Hòa Văn B'),
						 ('HD03', '5/01/2020', N'Ngô Thị La')
insert into CTHoaDon values('HD01', 'VT01', 65000, 25),
							('HD01', 'VT02', 85000, 10),
							('HD02', 'VT02', 85000, 21),
							('HD03', 'VT01', 65000, 30),
							('HD03', 'VT03', 20000, 10)
go

--test
select * from VatTu
select * from HoaDon
select * from CTHoaDon
go

/* Cau 2: */
create function fn_tongtien(@tenvt nvarchar(50), @ngayban date)
returns int
as
begin
	declare @tongtien int
	set @tongtien= (select sum(DonGiaBan*SLBan) from CTHoaDon where
			MaVT in (select MaVT from VatTu where TenVT=@tenvt)
			AND
			MaHD in (select MaHD from HoaDon where NgayLap=@ngayban) )
	return @tongtien
end
go

--test
select dbo.fn_tongtien(N'Cát vàng', '5/01/2020') as N'Tổng tiền'
go


/* Cau 3: */
create proc pro_tongluongVT(@thang int, @nam int, @soluong int output)
as
begin
	set @soluong = (select sum(SLBan) from CTHoaDon 
					where MaHD in (select MaHD from HoaDon where MONTH(NgayLap)=@thang AND YEAR(NgayLap)=@nam))
	return
end

go
--test
declare @month int
set @month = 4
declare @year int
set @year = 2020
declare @sl int

exec pro_tongluongVT @month, @year, @sl output

print N'Tổng số lượng vật tư bán trong tháng '+convert(varchar(2),@month)+'-'+convert(varchar(4),@year)+' là: '+convert(varchar(20),@sl)
go

/* Cau 4 */
create trigger trg_deleteCTHD on CTHoaDon for delete as
begin
	declare @mahd nvarchar(10)
	declare @mavt nvarchar(10)
	select @mahd=MaHD, @mavt=MaVT from deleted

	if((select count(*) from CTHoaDon where MaHD=@mahd)=0 AND (select count(*) from deleted)=1)
	begin
		raiserror(N'Đây là dòng duy nhất của hóa đơn',15,1)
		rollback tran
	end
	else
	begin
		update VatTu set SLCon = SLCon + deleted.SLBan from VatTu
		inner join deleted on deleted.MaVT=VatTu.MaVT
		where deleted.MaVT=VatTu.MaVT
	end
end

go

--test
select * from VatTu
select * from CTHoaDon

delete from CTHoaDon where MaHD='HD01' and MaVT='VT01'
select * from VatTu
select * from CTHoaDon

--loi

delete from CTHoaDon where MaHD='HD02'
go