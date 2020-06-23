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
						('H002', N'Khẩu trang y tế', N'Cái', 521230)
insert into HDBan values('HD001', '05-14-2020', N'Công Nghệ Thông Tin 5'),
						('HD002', '05-15-2020', N'Khoa Học Máy Tính')
insert into HangBan values('HD001', 'H001', 35000, 80),
							('HD001', 'H002', 5000, 80),
							('HD002', 'H001', 35000, 79),
							('HD002', 'H002', 5500, 79)
go

select * from Hang
select * from HDBan
select * from HangBan
go




/*                              *
 *============ DE 2 ============*
 *                              */




/* Cau 2: view */
create view TienHang as
select HDBan.MaHD, NgayBan, SUM(SoLuong*DonGia) as N'Tổng Tiền'
from HDBan inner join HangBan on HDBan.MaHD = HangBan.MaHD
group by HDBan.MaHD, NgayBan

go
--test
select * from TienHang
go

/* Cau 3: */
--Hơi sai đề bài, sửa chút là được!
--Không biết sửa thế nòa thì kéo xuống Câu 4 đề 7 nhé!
create proc sp_FindbyDateMonth(@date int, @month int)
as
begin
	(select Hang.MaHang, Hang.TenHang, HDBan.NgayBan, SoLuong, 
	case DATEPART(dw,HDBan.NgayBan)
		when 2 then N'Thứ Hai'
		when 3 then N'Thứ Ba'
		when 4 then N'Thứ Tư'
		when 5 then N'Thứ Năm'
		when 6 then N'Thứ Sáu'
		when 7 then N'Thứ Bẩy'
		when 1 then N'Chủ Nhật'
		else 'False'
	end as NgayThu
	from HangBan
	inner join Hang on Hang.MaHang = HangBan.MaHang
	inner join HDBan on HDBan.MaHD = HangBan.MaHD
	where @date = DAY(HDBan.NgayBan) AND @month = MONTH(HDBan.NgayBan)
	)

end

go

--test
exec sp_FindbyDateMonth 14,5
go

/* Cau 4 */
create trigger TRG_HangBan_Insert on HangBan for insert as
begin
	declare @SoLuong int
	declare @SLTon int
	declare @MaHang nvarchar(10)
	select @SoLuong = SoLuong, @MaHang=MaHang from inserted
	select @SLTon = SLTon from Hang where MaHang = @MaHang

	if(@SoLuong > @SLTon)
		begin
			raiserror('So luong trong kho khong du',16,1)
			rollback tran
			return
		end
	else
		update Hang set SLTon = SLTon-SoLuong from Hang
		inner join inserted on inserted.MaHang = Hang.MaHang
		where inserted.MaHang = Hang.MaHang
end

go
--test
insert into HDBan values('HD003', '05-15-2020', N'Công Nghệ Thông Tin 2')
insert into HangBan values('HD003', 'H001', 35000, 81)

select * from Hang
select * from HDBan
select * from HangBan
go





/*                              *
 *============ DE 7 ============*
 *                              */




/* Cau 2: view */
create view ThongTinHoaDon as
select HDBan.MaHD, COUNT(*) as N'Số mặt hàng'
from HangBan inner join HDBan on HDBan.MaHD=HangBan.MaHD
group by HDBan.MaHD
having count(*)>1
go

--test
select * from ThongTinHoaDon
go


/* Câu 3: function */
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

/* Câu 4: store procedure */
--Câu này gần giống câu 3 Đề 2 nhé
create proc sp_FindbyMonthYear(@month int, @year int)
as
begin
	(select Hang.MaHang, Hang.TenHang, HDBan.NgayBan, SoLuong, 
	case DATEPART(dw,HDBan.NgayBan)
		when 2 then N'Thứ Hai'
		when 3 then N'Thứ Ba'
		when 4 then N'Thứ Tư'
		when 5 then N'Thứ Năm'
		when 6 then N'Thứ Sáu'
		when 7 then N'Thứ Bẩy'
		when 1 then N'Chủ Nhật'
		else 'False'
	end as NgayThu
	from HangBan
	inner join Hang on Hang.MaHang = HangBan.MaHang
	inner join HDBan on HDBan.MaHD = HangBan.MaHD
	where @month = MONTH(HDBan.NgayBan) AND @year = YEAR(HDBan.NgayBan)
	)

end

go

--test
exec sp_FindbyMonthYear 5,2020
go






/*                              *
 *============ DE15 ============*
 *                              */





/* Cau 2 */
create view HoaDonTren1TR as
select MaHD, SUM(SoLuong * DonGia) as N'Tổng tiền'
from HangBan
group by MaHD
having SUM(SoLuong * DonGia) >= 1000000

go
--test
select * from HoaDonTren1TR
go

/* Cau 3; pro */
create proc PR_Delete_Hang(@MaHang nvarchar(10)) as
begin
	delete from HangBan where MaHang=@MaHang
	delete from Hang where MaHang=@MaHang
end
go

exec PR_Delete_Hang 'H001'
select * from Hang
select * from HangBan
go

/* Cau 4 */
create trigger trg_HoaDon_Inserted on HDBan for insert as
begin
	declare @NgayBan date
	select @NgayBan=NgayBan from inserted
	if(@NgayBan <> GETDATE())
	begin
		raiserror('Ngay Ban Khong Hop Le',16,1)
		rollback tran
		return
	end
end
go

insert into HDBan values('HD004', '05-15-2020', N'Kỹ Thuật Phần Mềm')
go