use master
go
if(exists(select * from sysdatabases where name='QLHANG'))
	drop database QLHANG
go

/* Cau 1 */
--create database
use master
go
create database QLHANG
go

use QLHANG
go

-- create table
create table Hang(
	MaHang nvarchar(10) not null primary key,
	TenHang nvarchar(30) not null,
	DVTinh nvarchar(20),
	SLTon int default 0
)

create table HDBan(
	MaHD nvarchar(10) not null primary key,
	NgayBan date default '01-01-1970',
	HoTenKhach nvarchar(30),
)

create table HangBan(
	MaHD nvarchar(10) not null,
	MaHang nvarchar(10) not null,
	DonGia money default 0,
	SoLuong int default 0,
	constraint PRI_KEY_HangBan primary key(MaHD, MaHang),
	constraint HangBan_Hang foreign key(MaHang) references Hang(MaHang),
	constraint HangBan_HDBan foreign key(MaHD) references HDBan(MaHD)
)

go

-- insert

insert into Hang values('H001', N'Nước rửa tay sát khuẩn', N'Lọ', 22230),
						('H002', N'Khẩu trang y tế', N'Cái', 521230),
						('H003', N'Cồn 90 độ', N'Lọ', 20)
insert into HDBan values('HD001', '05-14-2020', N'Nam Phạm'),
						('HD002', '05-15-2020', N'Tên Thôi')
insert into HangBan values('HD001', 'H001', 35000, 80),
							('HD001', 'H002', 5000, 80),
							('HD002', 'H001', 35000, 79),
							('HD002', 'H002', 5500, 79)
go

select * from Hang
select * from HDBan
select * from HangBan
go

/* Cau 2 */
create view TongSLBan as
select Hang.MaHang, TenHang, SUM(SoLuong) as SoLuongBan
from Hang inner join HangBan on HangBan.MaHang = Hang.MaHang
group by Hang.MaHang, TenHang

go

create view MaxTongSLBan as
select * from TongSLBan where SoLuongBan = (select MAX(SoLuongBan) from TongSLBan)

go

--test
select * from MaxTongSLBan

go

/* Cau 3 */
create function tongtienban(@nam int)
returns money as
begin
	declare @tongtien money
	select @tongtien=SUM(DonGia*SoLuong) from HangBan
	where MaHD in (select MaHD from HDBan where YEAR(NgayBan)=@nam)
	return @tongtien
end
go

--test

select dbo.tongtienban(2020) as N'Tổng tiền bán năm 2020'
go

/* Cau 4 */
create trigger trg_insertHangBan on HangBan for insert as
begin
	declare @soluong int
	declare @soluongton int
	declare @mahang nvarchar(10)

	select @soluong=SoLuong, @mahang=MaHang from inserted
	select @soluongton=SLTon from Hang where MaHang=@mahang

	if(@soluong>@soluongton)
	begin
		raiserror(N'Không đủ hàng tồn để xuất',16,1)
		rollback tran
	end
	else
		update Hang set SLTon=SLTon-@soluong where MaHang=@mahang
end

go

--test

--loi
insert into HangBan values('HD002', 'H003', 5000, 80)

--thanh cong
insert into HangBan values('HD002', 'H003', 5000, 20)
select * from HangBan
select * from Hang