use master
go
if(exists(select * from sysdatabases where name='QLBH'))
	drop database QLBH;

go

use master
go
--1 Create database
create database QLBH

go

use QLBH

go


/* ========== DUOI DAY LA VI DU  ========== */

---- TABLE VI DU ----
CREATE TABLE HANG(
	MAHANG INT NOT NULL IDENTITY PRIMARY KEY,
	TENHANG NVARCHAR(30) NOT NULL,
	SOLUONG INT DEFAULT 0,
	GIABAN MONEY
)

CREATE TABLE HOADON(
	MAHD INT NOT NULL PRIMARY KEY,
	MAHANG INT NOT NULL,
	SOLUONGBAN INT DEFAULT 0,
	NGAYBAN DATETIME,
	CONSTRAINT FK_HD_HANG FOREIGN KEY(MAHANG) REFERENCES HANG(MAHANG)
)
GO

---- INSERT VO VAN ----
INSERT INTO HANG VALUES(N'KHẨU TRANG Y TẾ', 50, 1200000),
						(N'NƯỚC RỬA TAY KHÔ', 100, 50000),
						(N'CỒN SÁT TRÙNG', 50, 5000),
						(N'GIẤY VỆ SINH', 200, 60000),
						(N'MỲ TÔM', 300, 98000),
						(N'KHẨU TRANG N95', 50, 2200000)
GO
/* ---VD1: MUA 1 MAT HANG, 
-HAY KIEM TRA XEM HANG DO CO TON TAI HAY KHONG
NEU KHONG HAY DUA RA THONG BAO
NEU THOA MAN HAY KIEM TRA XEM SOLUONGBAN <= SOLUONG?
NEU KHONG HAY DUA RA THONG BAO 
- NGUOC LAI CAP NHAT LAI BANG HANG VOI SOLUONG = SOLUONG - SOLUONGBAN */


CREATE TRIGGER TRG_HOADON_INSERT ON HOADON FOR INSERT
AS
BEGIN
	DECLARE @MAHANG INT
	SET @MAHANG = (SELECT MAHANG FROM inserted)
	IF(NOT EXISTS(SELECT * FROM HANG WHERE MAHANG=@MAHANG))
		BEGIN
			RAISERROR('MAT HANG KHONG TON TAI',16,1)
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			DECLARE @SOLUONGBAN INT
			DECLARE @SOLUONGCO INT

			SET @SOLUONGBAN = (SELECT SOLUONGBAN FROM inserted)
			SET @SOLUONGCO = (SELECT SOLUONG FROM HANG WHERE MAHANG=@MAHANG)

			IF(@SOLUONGBAN > @SOLUONGCO)
				BEGIN
					RAISERROR('KHONG DU HANG DE BAN',16,1)
					ROLLBACK TRANSACTION
				END
			ELSE
				UPDATE HANG SET SOLUONG=SOLUONG-@SOLUONGBAN WHERE MAHANG = @MAHANG
		END
END
GO
--TEST

SELECT * FROM HANG
SELECT * FROM HOADON
INSERT INTO HOADON VALUES(1,3,25,'2/9/1999')
INSERT INTO HOADON VALUES(2,3,10,'04/30/2020')
SELECT * FROM HANG
SELECT * FROM HOADON

GO

/* VD2: KHACH HANG KHONG MUON MUA 1 MAT HANG CO HOA DON XYZ NUA TA PHAI XOA DON HANG NAY DI, 
LUC NAY DU LIEU TRUOC LUC XOA TRONG BANG DON HANG NAM TRONG BANG DELETED
--LUC NAY BANG HANG SE DUOC CAP NHAT SOLUONG SOLUONG + DELETED.SOLUONGBAN */

CREATE TRIGGER TRG_HOADON_DELETE ON HOADON FOR DELETE
AS
BEGIN
	DECLARE @MAHANG INT
	DECLARE @SOLUONGBAN INT
	SELECT @MAHANG=MAHANG, @SOLUONGBAN=SOLUONGBAN FROM deleted

	UPDATE HANG SET SOLUONG=SOLUONG+@SOLUONGBAN WHERE MAHANG=@MAHANG
END

GO
--TEST

SELECT * FROM HANG
SELECT * FROM HOADON
DELETE FROM HOADON WHERE MAHD=1
SELECT * FROM HANG
SELECT * FROM HOADON

GO

/*VD3: KHACH HANG MUA HANG ROI DUNG KHONG HET TRA LAI 1 SO HANG 
KHI DO CAN UPDATE SOLUONGBAN TRONG BANG HOADON 
VA CUNG CAN UPDATE SOLUONG TRONG BANG HANG */

CREATE TRIGGER TRG_HOADON_UPDATE ON HOADON FOR UPDATE AS
BEGIN
	DECLARE @TRUOC INT
	DECLARE @SAU INT
	DECLARE @MAHANG INT

	SELECT @TRUOC=SOLUONGBAN, @MAHANG=MAHANG FROM deleted
	SELECT @SAU=SOLUONGBAN FROM inserted

	IF(UPDATE(SOLUONGBAN))
		UPDATE HANG SET SOLUONG=SOLUONG-(@SAU-@TRUOC) WHERE MAHANG=@MAHANG
END

GO
--TEST
SELECT * FROM HANG
SELECT * FROM HOADON
UPDATE HOADON SET SOLUONGBAN=SOLUONGBAN-5 WHERE MAHANG=3
SELECT * FROM HANG
SELECT * FROM HOADON

GO





/*  ========== PHAM NAY LA PHAN BAI TAP  ========== */





--create table bai tap
CREATE TABLE MATHANG (
	mahang nvarchar(5) not null primary key,
	tenhang nvarchar(30) not null,
	soluong int default 0
)

CREATE TABLE NHATKYBANHANG(
	stt int not null identity primary key,
	ngay date,
	nguoimua nvarchar(30),
	mahang nvarchar(5) not null,
	soluong int,
	giaban money,
	constraint fk_MH_NKBH foreign key(mahang) references MATHANG(mahang)
)

go
--2 insert table
insert into MATHANG values('1', 'Keo', 100), ('2', 'Banh', 200), ('3', 'Thuoc', 100)
insert into NHATKYBANHANG values('02/09/1999','ab',2,230,50)

go


--3 create trigger

/*a.trg_nhatkybanhang_insert.
Trigger này có chức năng tự động giảm số lượng hàng hiện có 
(Trong bảng MATHANG) khi một mặt hàng nào đó được bán 
(tức là khi câu lệnh INSERT được thực thi trên bảng NHATKYBANHANG). */

create trigger trg_nhatkybanhang_insert
on NHATKYBANHANG for insert
as
	update MATHANG set MATHANG.soluong = MATHANG.soluong - inserted.soluong
	from MATHANG inner join inserted on MATHANG.mahang = inserted.mahang

go
--test
select * from MATHANG
select * from NHATKYBANHANG

insert into NHATKYBANHANG values('2/9/1999','ab','2',30,50)

select * from MATHANG
select * from NHATKYBANHANG

go

/*b.trg_nhatkybanhang_update_soluong
được kích hoạt khi ta tiến hành cập nhật cột SOLUONG 
cho một bản ghi của bảng NHATKYBANHANG 
(lưu ý là chỉ cập nhật đúng một bản ghi).*/

create trigger trg_nhatkybanhang_update_soluong
on NHATKYBANHANG for update
as
begin
	if((select count(*) from inserted)>1)
		begin
			raiserror('Khong duoc update nhieu ban ghi cung luc',16,1)
			rollback tran
			return
		end
	else
		begin
			declare @truoc int
			declare @sau int
			declare @mahang nvarchar(5)
			select @truoc = soluong from deleted
			select @sau = soluong, @mahang = mahang  from inserted
			if(@truoc<>@sau)
				begin
					update MATHANG set MATHANG.soluong = MATHANG.soluong-(@sau-@truoc)
					where MATHANG.mahang = @mahang
				end
		end
end

go
--test
select * from mathang
select * from nhatkybanhang
UPDATE nhatkybanhang SET soluong=soluong+20  WHERE stt=1
select * from mathang
select * from nhatkybanhang

go

/*
c.	Trigger dưới đây được kích hoạt khi câu lệnh INSERT
được sử dụng để bổ sung một bản ghi mới cho bảng NHATKYBANHANG.
Trong trigger này kiểm tra điều kiện hợp lệ của dữ liệu
là số lượng hàng bán ra phải nhỏ hơn hoặc bằng số lượng hàng hiện có. 
Nếu điều kiện này không thoả mãn thì huỷ bỏ thao tác bổ sung dữ liệu. */

create trigger trg_NKBH_insert
on NhatKyBanHang
for insert
as
begin
	declare @sl_co int
	declare @sl_ban int
	declare @mahang int

	select @mahang=mahang, @sl_ban=soluong from inserted
	select @sl_co=soluong from mathang where mahang=@mahang

	if(@sl_co<@sl_ban)
		rollback transaction
	else
		update mathang set soluong=soluong-@sl_ban where mahang=@mahang
end

go
--test
select * from mathang
select * from NhatKyBanHang
insert into NhatKyBanHang values('2/9/1999','ab',2,10,50)
select * from mathang
select * from NhatKyBanHang

go

/*d.Trigger duoi day nham de kiem soat loi update bang nhatkybanhang, 
neu update >1 ban ghi thi thong bao loi(Trigger chi lam tren 1 ban ghi), 
quay tro ve. Nguoc lai thi update lai so luong cho bang mathang.*/

create trigger trg_update_NKBH
on NhatKyBanHang
for update as
begin
	declare @mahang int
	declare @truoc int
	declare @sau int
	if((select count(*) from inserted)>1)
	begin
		raiserror('Khong duoc sua qua 1 dong lenh',16,1)
		rollback tran
		return
	end
	else
		if(update(soluong))
		begin
			select @truoc=soluong from deleted
			select @sau=soluong from inserted
			select @mahang=mahang from inserted

			update mathang set soluong=soluong -(@SAU-@TRUOC)
			where mahang=@mahang
		end
end

go
--test
select * from mathang
select * from nhatkybanhang
UPDATE nhatkybanhang SET soluong=soluong+20 WHERE stt=1
select * from mathang
select * from nhatkybanhang

go

/* e.	Hay tao Trigger xoa 1 ban ghi bang nhatkybanhang, 
neu xoa nhieu hon 1 record thi hay thong bao loi xoa ban ghi, 
nguoc lai hay update bang mathang voi cot so luong tang len
 voi ma hang da xoa o bang nhatkybanhang.*/

create trigger trg_delete_NKBH on NhatKyBanHang for delete as
begin
	declare @mahang int
	declare @soluongxoa int
	if((select count(*) from deleted)>1)
	begin
		raiserror('Khong duoc xoa lon hon 1 ban ghi',16,1)
		rollback tran
		return
	end
	else
	begin
		select @mahang=mahang,@soluongxoa=soluong from deleted
		update mathang set soluong=soluong+@soluongxoa where mahang=@mahang
	end

end

go
--test
select * from mathang
select * from nhatkybanhang
DELETE from nhatkybanhang WHERE stt=1
select * from mathang
select * from nhatkybanhang

go


/* f.Tạo Trigger cập nhật bảng nhật ký bán hàng, 
nếu cập nhật nhiều hơn 1 bản ghi thông báo lỗi và phục hồi phiên giao dịch, 
ngược lại kiểm tra xem nếu giá trị số lượng cập nhật <giá trị số lượng 
có thì thông báo lỗi sai cập nhật, 
ngược lại nếu  nếu giá trị số lượng cập nhật =giá trị số lượng 
có thì thông báo không cần cập nhật ngược lại thì hãy cập nhật giá trị. */

create trigger trg_update_NKBH2 on NhatKyBanHang for update as
begin
	declare @mahang int
	declare @truoc int
	declare @sau int
	if((select count(*) from inserted)>1)
	begin
		raiserror('Khong duoc sua qua 1 dong lenh',16,1)
		rollback tran
		return
	end
	else
	begin
		select @truoc=soluong from deleted
		select @sau=soluong from inserted
		select @mahang=mahang from inserted
		if(@sau<@truoc)
		begin
			raiserror('Loi sai cap nhap',16,1)
			rollback tran
			return
		end
		else
			if(@sau=@truoc)
			begin
				raiserror('Khong can cap nhap',16,1)
				rollback tran
				return
			end
			else
			begin
				update mathang set soluong=soluong -(@SAU-@TRUOC)
				where mahang=@mahang
			end
	end
end

go
--test

select * from mathang
select * from nhatkybanhang
UPDATE nhatkybanhang SET soluong=soluong+20 WHERE stt=1
select * from mathang
select * from nhatkybanhang

go

/*g.Viết thủ tục xóa 1 bản ghi trên bảng mathang, 
voi mahang được nhập từ bàn phím. Kiểm tra xem mahang co tồn tại hay không, 
nếu không đưa ra thông báo, ngược lại hãy xóa, có tác động đến 2 bảng. */

create proc sp_delete_mathang(@mah int) as
begin
	if(not exists(select * from mathang where mahang=@mah))
		print('San pham khong ton tai')
	else
	begin
		delete from nhatkybanhang where mahang=@mah
		delete from mathang where mahang=@mah
	end
end

go
--test
select * from mathang
select * from nhatkybanhang
exec sp_delete_mathang 1
select * from mathang
select * from nhatkybanhang

go

/*h.Viết 1 hàm tính tổng tiền của 1 mặt hàng có tên hàng được nhập từ bàn phím.*/

create function fn_tongtien(@tenmh nvarchar(30))
returns money as
begin
	declare @sum money
	set @sum = (select sum(giaban*NhatKyBanHang.soluong) from NhatKyBanHang 
				inner join mathang on NhatKyBanHang.mahang=mathang.mahang
				where tenhang=@tenmh)
	return @sum
end

go

select * from mathang
select * from nhatkybanhang
select dbo.fn_tongtien('Banh') as N'Tong tien'
go