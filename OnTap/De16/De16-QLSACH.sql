use master
go
if(exists(select * from sysdatabases where name='QLSACH'))
	drop database QLSACH
go

/* Cau 1 */
-- create database
use master
go
create database QLSACH
go

use QLSACH
go
-- create table
create table TG(
	MaTG nvarchar(10) not null primary key,
	TenTG nvarchar(30) not null
)
create table NXB(
	MaNXB nvarchar(10) not null primary key,
	TenNXB nvarchar(30) not null
)
create table Sach(
	Masach nvarchar(10) not null primary key,
	tensach nvarchar(30) not null,
	slco int default 0,
	MaTG nvarchar(10) not null,
	MaNXB nvarchar(10) not null,
	ngayxb date,
	constraint Sach_TG foreign key(MaTG) references TG(MaTG),
	constraint Sach_NXB foreign key(MaNXB) references NXB(MaNXB)
)

go

-- insert data
insert into TG values('TG1', N'Tô Hoài'), ('TG2', N'Nguyễn Nhật Ánh')
insert into NXB values('NXB1', N'Kim Đồng'), ('NXB2', N'NXB Trẻ')
insert into Sach values('H001', N'Dế mèn phưu lưu ký', 54, 'TG1', 'NXB1', '02-21-2019'),
						('H002', N'Vợ chồng A Phủ', 100, 'TG1', 'NXB1', '06-05-2018'),
						('H003', N'Cô gái đến từ hôm qua', 66, 'TG2', 'NXB1', '05-12-2017'),
						('H004', N'Mắt biếc', 150, 'TG2', 'NXB2', '12-16-2017'),
						('H005', N'Làm bạn với bầu trời', 22, 'TG2', 'NXB2', '01-30-2018')



go

/* Cau 2 */
create view ThongKeTG as
select TG.MaTG, TenTG, COUNT(*) as N'Số sách đã viết' from TG
inner join Sach on TG.MaTG = Sach.MaTG
group by TG.MaTG, TenTG

go
--test
select * from ThongKeTG
go


/* Cau 3 */
create function FN_TKbyMaTG(@MTG nvarchar(10))
returns @Data table(MaTG nvarchar(10), TenTG nvarchar(30), SoSachDaViet int)
as
begin
	insert into @Data 
	select TG.MaTG, TenTG, COUNT(*) from TG
	inner join Sach on TG.MaTG = Sach.MaTG
	where TG.MaTG = @MTG
	group by TG.MaTG, TenTG

	return
end

go
--test
select * from FN_TKbyMaTG('TG1')
go

/* Cau 4 */

create trigger TRG_Sach_Insert on Sach for insert as
begin
	declare @ngayxb date
	select @ngayxb = ngayxb from inserted
	if(@ngayxb >= GETDATE())
		begin
			raiserror('Ngay xuat ban khong hop le',16,1)
			rollback tran
			return
		end
end
go
insert into Sach values('H006', N'Tôi thấy hoa vàng trên cỏ xanh', 4, 'TG1', 'NXB1', '02-22-2021')
select * from Sach
go