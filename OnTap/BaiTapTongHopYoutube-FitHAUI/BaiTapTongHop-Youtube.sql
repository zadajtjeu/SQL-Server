use master
go
if(exists(select * from sysdatabases where name='QLbanhang'))
	drop database QLbanhang
go
/* Cau 1: */
use master 
create database QLbanhang
go

use QLbanhang
go

-- create table
create table congty(
	MaCT nvarchar(10) not null primary key,
	TenCT nvarchar(50) not null,
	trangthai nvarchar(20),
	ThanhPho nvarchar(50)
)
create table sanpham(
	MaSP nvarchar(10) not null primary key,
	TenSP nvarchar(50) not null,
	MauSac nvarchar(10),
	SoLuong int default 0,
	giaban money default 0
)
create table CungUng(
	MaCT nvarchar(10) not null,
	MaSP nvarchar(10) not null,
	SoLuongCungUng int default 0,
	constraint FK_Cungung primary key(MaCT, MaSP),
	constraint CU_CT foreign key(MaCT) references CongTy(MaCT),
	constraint CU_SP foreign key(MaSP) references SanPham(MaSP)
)

go

-- insert data
insert into congty values('CT01', N'Samsung', N'Hoạt động', N'Bắc Ninh'),
						('CT02', N'Nokia', N'Hoạt động', N'Hà Nội'),
						('CT03', N'LG', N'Hoạt động', N'Bắc Ninh')
insert into sanpham values('SP01', N'Nokia 3', N'Trắng', 120, 3400000),
							('SP02', N'Note 10', N'Xanh', 200, 6400000),
							('SP03', N'Galaxy s10', N'Đen', 100, 7400000)
insert into CungUng values('CT01', 'SP02', 100), ('CT01', 'SP03', 50), 
						('CT02', 'SP01', 120), ('CT03', 'SP02', 100), 
						('CT02', 'SP03', 50)

go

select * from congty
select * from sanpham
select * from CungUng
go

/* Cau 2: */
create function FN_SPbyCT(@TenCT nvarchar(50))
returns @result table(TenSP nvarchar(50), MauSac nvarchar(10), SoLuong int, GiaBan money)
as
begin
	insert into @result
		select TenSP, MauSac, SoLuong, GiaBan from SanPham
		where MaSP in (Select MaSP from CungUng 
						where MaCT = (select MaCT from CongTy where TenCT = @TenCT)
					)
	return
end

go
--test
select * from FN_SPbyCT(N'Samsung')
go

/* Cau 3: */
create proc PRO_FindSPbyTenCT(@TenCT nvarchar(50))
as
begin
	declare @count int
	set @count = (select count(*) from congty where TenCT = @TenCT)
	if(@count <> 0)
	begin
		select TenSP, MauSac, SoLuong, GiaBan from SanPham
		where MaSP in (Select MaSP from CungUng 
						where MaCT = (select MaCT from CongTy where TenCT = @TenCT)
					)
	end
	else
		print(N'công ty không tồn tại')
end

go
exec PRO_FindSPbyTenCT N'Nokia'
go
/* Cau 4 */
create trigger TRG_Update_SoLuong_CungUng on CungUng for update as
begin
if UPDATE(soluongcungung)
	begin

	declare @soluongcu int
	declare @soluongmoi int
	declare @soluong int
	select @soluongcu=soluongcungung from deleted
	select @soluongmoi=soluongcungung from inserted
	select @soluong=soluong from sanpham inner join inserted on inserted.MaCT=sanpham.MaSP

	if(@soluongcu - @soluongmoi > @soluong)
		begin
		raiserror(N'Số lượng trong kho không đủ để cung ứng',16,1)
		rollback transaction
		return
		end
	else
		begin
		update SanPham set soluong=soluong-(@soluongcu - @soluongmoi) from SanPham
			inner join inserted on Sanpham.MaSP = inserted.MaSP
		end

	end

end
go
select * from SanPham
select * from CungUng
update CungUng set SoLuongCungUng=SoLuongCungUng-100 where MaSP='SP01'
go
select * from SanPham
select * from CungUng
