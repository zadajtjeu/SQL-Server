use master
go
if(exists(select * from sysdatabases where name='QLbanhang'))
	drop database QLbanhang
go

/* Cau 1: Create database */
use master
go
create database QLbanhang
go

use QLbanhang
go

--create table
create table CONGTY(
	MaCT nvarchar(10) not null primary key,
	TenCT nvarchar(50),
	trangthai nvarchar(20),
	ThanhPho nvarchar(30)
)
create table SANPHAM(
	MaSP nvarchar(10) not null primary key,
	TenSP nvarchar(50),
	mausac nvarchar(10),
	soluong int default 0,
	giaban money default 0
)
create table CUNGUNG(
	MaCT nvarchar(10) not null references CONGTY(MaCT),
	MaSP nvarchar(10) not null references SANPHAM(MaSP),
	SoluongCungung int default 0,
	ngaycungung date,
	constraint fk_CU primary key(MaCT, MaSP)
)

go

-- insert data
insert into CONGTY values('CT1', N'Công ty cổ phần Một bit', N'Hoạt động', N'Hà Nội'),
						('CT2', N'Công ty cổ phần Hateco', N'Hoạt động', N'Hà Nội'),
						('CT3', N'Công ty TNHH Bảo Việt', N'Hoạt động', N'Hà Nội')
insert into SANPHAM values('SP1', N'Đông trùng hạ thảo khô', N'Vàng', 200, 850000),
						  ('SP2', N'Mật ong sú vẹt', N'Nâu', 150, 250000),
						  ('SP3', N'Sâm Ngọc Linh', N'Nâu', 200, 1500000)
insert into CUNGUNG values('CT1', 'SP1', 100, '12/05/2019'),
							('CT1', 'SP2', 150, '04/05/2020'),
							('CT2', 'SP3', 100, '04/05/2020'),
							('CT3', 'SP3', 200, '04/05/2020'),
							('CT3', 'SP1', 100, '04/05/2020')

go

--test
select * from CONGTY
select * from SANPHAM
select * from CUNGUNG
go


/* Cau 2 */
create function fn_tongtiencungung(@tenct nvarchar(50), @nam int)
returns money
as
begin
	declare @tongtien money
	set @tongtien = (select sum(Soluongcungung*giaban) from CUNGUNG
					inner join SANPHAM on SANPHAM.MaSP=CUNGUNG.MaSP
					where @nam=YEAR(ngaycungung) and
					MaCT in (select MaCT from CONGTY where TenCT=@tenct))
	return @tongtien
end

go

--test
select dbo.fn_tongtiencungung(N'Công ty cổ phần Một bit', 2020) as N'Tổng tiền cung ứng'

go

/* Cau 3: */
create proc pro_addnewcungung(@tenct nvarchar(50), @tensp nvarchar(50), @soluongcungung int, @ngaycungung date)
as
begin
	declare @mact nvarchar(10)
	declare @masp nvarchar(10)
	
	if(exists(select * from CONGTY where TenCT=@tenct))
		select @mact=MaCT from CONGTY where TenCT=@tenct
	else
		return 0
	if(exists(select * from SANPHAM where TenSP=@tensp))
		select @masp=MaSP from SANPHAM where TenSP=@tensp
	else
		return 0
	insert into CUNGUNG values(@mact, @masp, @soluongcungung, @ngaycungung)
	return 1
end

go
--test
declare @check int

exec @check = pro_addnewcungung N'Công ty cổ phần Một bit', N'Sâm Ngọc Linh', 200, '05/22/2020'
if(@check = 0)
	print N'Thêm 1 cung ứng không thành công'
else
	select * from CUNGUNG

go

/* Cau 4 */
create trigger trig_insertCU on CUNGUNG for insert as
begin
	declare @slcu int, @sl int, @masp nvarchar(10)
	select @slcu=soluongcungung, @masp=MaSP from inserted
	select @sl=soluong from SANPHAM where MaSP=@masp

	if(@slcu>@sl)
	begin
		raiserror(N'Số lượng sản phẩm không đủ!',16,1)
		rollback tran
	end
	else
		update SANPHAM set soluong=soluong-@slcu where MaSP=@masp
end

go

--test
insert into CUNGUNG values('CT2', 'SP2', 100,'06/24/2020')
select * from CUNGUNG
select * from SANPHAM
--error
insert into CUNGUNG values('CT2', 'SP1', 201,'06/24/2020')
go