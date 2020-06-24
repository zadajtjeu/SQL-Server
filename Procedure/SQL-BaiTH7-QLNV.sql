use master
go

if(exists(select * from sysdatabases where name='QLNV'))
	drop database QLNV
go

-- A.create database
USE MASTER
GO
create database QLNV

go

--B.create table
USE QLNV
GO
create table tblChucvu(
	MaCV nvarchar(2) not null primary key,
	TenCV nvarchar(30)
)

create table tblNhanVien(
	MaNV nvarchar(4) not null primary key,
	MaCV nvarchar(2),
	TenNV nvarchar(30),
	NgaySinh datetime,
	LuongCanBan float,
	NgayCong int,
	PhuCap float,
	constraint fk_NV_CV foreign key(MaCV) references tblChucVu(MaCV)
)

go
--C. insert data
insert into tblChucVu values ('BV',N'Bảo Vệ'), ('GD',N'Giám Đốc'),
							('HC',N'Hành Chính'), ('KT',N'Kế Toán'),
							('TQ',N'Thủ Quỹ'), ('VS',N'Vệ Sinh')
insert into tblNhanVien values ('NV01', 'GD', N'Nguyễn Văn An', '12/12/1977 12:00:00', 700000, 25, 500000),
								('NV02', 'BV', N'Bùi Văn Tí', '10/10/1978 12:00:00', 400000, 24, 100000),
								('NV03', 'KT', N'Trần Thanh Nhật', '9/9/1977 12:00:00', 600000, 26, 400000),
								('NV04', 'VS', N'Nguyễn Thị Út', '10/10/1980 12:00:00', 300000, 26, 300000),
								('NV05', 'HC', N'Lê Thị Hà', '10/10/1979 12:00:00', 500000, 27, 200000)
go

select * from tblChucvu
select * from tblNhanVien

go

/*D.a Viết thủ tục SP_Them_Nhan_Vien,
 biết tham biến là MaNV, MaCV, TenNV,Ngaysinh,LuongCanBan,NgayCong,PhuCap.
 Kiểm tra MaCV có tồn tại trong bảng tblChucVu hay không, 
 nếu có thì kiểm tra xem ngày công có <=30 hay không?
 nếu thảo mãn yêu cầu thì cho thêm nhân viên mới, nếu không thì đưa ra thông báo. */

 create proc SP_Them_Nhan_Vien (@MaNV nvarchar(5), @MaCV nvarchar(2), @TenNV nvarchar(30), @NgaySinh datetime, @LuongCanBan float, @NgayCong int, @PhuCap float)
 as
 begin
	if(not exists(select * from tblChucVu where MaCV=@MaCV))
		print(N'Chức vụ không tồn tại trên hệ thống')
	else if(@NgayCong >30)
		print(N'Ngày công không hợp lệ')
	else
		insert into tblNhanVien values (@MaNV, @MaCV, @TenNV, @NgaySinh, @LuongCanBan, @NgayCong, @PhuCap)
 end

 go

 exec SP_Them_Nhan_Vien 'NV06', 'S', N'Phan Văn Khôi', '2/9/1999', 120000,36, 100000
 exec SP_Them_Nhan_Vien 'NV06', 'VS', N'Phan Văn Khôi', '2/9/1999', 120000,36, 100000
 exec SP_Them_Nhan_Vien 'NV06', 'VS', N'Phan Văn Khôi', '2/9/1999', 120000,30, 100000
 select * from tblNhanVien
 go

 /*
 D. b. Viết thủ tục SP_CapNhat_Nhan_Vien ( không cập nhật mã), 
 biết tham biến là MaNV, MaCV, TenNV,Ngaysinh,LuongCanBan,NgayCong,PhuCap. 
 Kiểm tra MaCV có tồn tại trong bảng tblChucVu hay không, 
 nếu có thì kiểm tra xem ngày công có <=30 hay không? 
 nếu thỏa mãn yêu cầu thì cho cập nhật, nếu không thì đưa ra thông báo. */

create proc SP_CapNhat_Nhan_Vien(@MaNV nvarchar(5), @MaCV nvarchar(2), @TenNV nvarchar(30), @NgaySinh datetime, @LuongCanBan float, @NgayCong int, @PhuCap float)
as
begin
	if(not exists(select * from tblChucVu where MaCV=@MaCV))
		print(N'Chức vụ không tồn tại trên hệ thống')
	else if(@NgayCong >30)
		print(N'Ngày công không hợp lệ')
	else
		update tblNhanVien set MaCV=@MaCV, TenNV=@TenNV, NgaySinh=@NgaySinh, LuongCanBan=@LuongCanBan,NgayCong=@NgayCong,PhuCap=@PhuCap WHERE MaNV=@MaNV
end

go

 exec SP_CapNhat_Nhan_Vien 'NV06', 'S', N'Phan Văn Khôi', '2/9/1999', 100000,36, 100000
 exec SP_CapNhat_Nhan_Vien 'NV06', 'VS', N'Phan Văn Khôi', '2/9/1999', 100000,36, 100000
 exec SP_CapNhat_Nhan_Vien 'NV06', 'VS', N'Phan Văn Khôi', '2/9/1999', 100000,25, 100000
 select * from tblNhanVien
 go

/* D.c. Viết thủ tục SP_LuongLN với Luong=LuongCanBan*NgayCong+PhuCap,
biết thủ tục trả về, không truyền tham biến. */

create proc SP_LuongLN as
begin
	select TenNV, LuongCanBan*NgayCong+PhuCap as N'Lương' from tblNhanVien
end

go

exec SP_LuongLN

go

/*D.d. Viết hàm nội tuyến tính lương trung bình của các nhân viên và thể hiện các thông tin sau 
MaNV,TenNV,TenCV,Luong với Luong=LuongCanBan*NgayCong + PhuCap
Nhưng nếu NgayCong>=25 thì số ngày dư ra được tính gấp đôi, 
kết quả trả về 1 bảng TB lương các nhân viên.*/
/*
create function fn_TinhLuong()
returns @bangluong table (MaNV nvarchar(5), TenNV nvarchar(30), TenCV nvarchar(30), Luong float)
as
begin
	declare @ngayc int
	set @ngayc = (select NgayCong from tblNhanVien)
	if(@ngayc >= 25)
	begin
		insert into @bangluong
			select MaNV, TenNV, TenCV, LuongCanBan*NgayCong+PhuCap+(NgayCong-25)*LuongCanBan as N'Lương' from tblNhanVien inner join tblChucVu on tblNhanVien.MaCV=tblChucvu.MaCV
	end
	else
	begin
		insert into @bangluong
			select MaNV, TenNV, TenCV, LuongCanBan*NgayCong+PhuCap as N'Lương' from tblNhanVien inner join tblChucVu on tblNhanVien.MaCV=tblChucvu.MaCV
	end
	return
end
go

select * from fn_TinhLuong()


go
--câu trên sai cmnr

*/


/*1.	Tạo  thủ tục có tham  số đưa vào là
 MaNV, MaCV, TenNV, NgaySinh,  LuongCB, NgayCong, PhucCap. 
 Trước khi chèn một bản ghi mới vào bảng NHANVIEN
  với danh sách giá trị là giá trị của các biến phải kiểm tra 
  xem MaCV  đã tồn tại bên bảng ChucVu chưa, nếu chưa trả ra 0.
*/
GO
CREATE PROC SP_THEM_NHAN_VIEN1
                   ( @MANV NVARCHAR(4),
                     @MACV NVARCHAR(2),
                     @TENNV NVARCHAR(30),
                     @NGAYSINH DATETIME,
                     @LUONGCANBAN FLOAT,
                     @NGAYCONG INT,
                     @PHUCAP FLOAT,
                     @KQ INT OUTPUT
                    )
AS
   BEGIN
      IF(NOT EXISTS(SELECT * FROM TBLCHUCVU WHERE MACV=@MACV))
         SET @KQ=0
      ELSE
         IF(NOT EXISTS(SELECT * FROM TBLNHANVIEN WHERE MANV=@MANV AND MACV=@MACV AND @NGAYCONG<=30)) 
            SET @KQ=0  
         ELSE
            INSERT INTO TBLNHANVIEN VALUES(
                     @MANV,
                     @MACV,
                     @TENNV,
                     @NGAYSINH,
                     @LUONGCANBAN,
                     @NGAYCONG,
                     @PHUCAP
                     )
       RETURN @KQ
   END
GO
---TEST        
   DECLARE @ERROR INT
   EXEC SP_THEM_NHAN_VIEN1 'NV007','VS',N'Phạm Chàm','2/9/1999', 120000,36, 100000,@ERROR OUTPUT
   SELECT @ERROR
GO


/*2.	Sửa thủ tục ở câu một kiểm tra xem  thêm MaNV  được chèn vào 
có trùng với MaNV nào đó có trong bảng không. 
Nếu MaNV đã tồn tại trả ra 0, 
nếu MaCV chưa tồn tại trả ra 1.
 Ngược lại cho phép chèn bản ghi.*/


GO
ALTER PROC SP_THEM_NHAN_VIEN1
                   ( @MANV NVARCHAR(4),
                     @MACV NVARCHAR(2),
                     @TENNV NVARCHAR(30),
                     @NGAYSINH DATETIME,
                     @LUONGCANBAN FLOAT,
                     @NGAYCONG INT,
                     @PHUCAP FLOAT,
                     @KQ INT OUTPUT
                    )
AS
   BEGIN
      IF(NOT EXISTS(SELECT * FROM TBLCHUCVU WHERE MACV=@MACV))
         SET @KQ=0
      ELSE IF(EXISTS(SELECT * FROM tblNhanVien WHERE MANV=@MANV))
		SET @KQ=0
      ELSE
         IF(NOT EXISTS(SELECT * FROM TBLNHANVIEN WHERE MANV=@MANV AND MACV=@MACV AND @NGAYCONG<=30)) 
            SET @KQ=0  
         ELSE
            INSERT INTO TBLNHANVIEN VALUES(
                     @MANV,
                     @MACV,
                     @TENNV,
                     @NGAYSINH,
                     @LUONGCANBAN,
                     @NGAYCONG,
                     @PHUCAP
                     )
       RETURN @KQ
   END
GO
---TEST        
   DECLARE @ERROR INT
   EXEC SP_THEM_NHAN_VIEN1 'NV007','VS',N'Phạm Chàm','2/9/1999', 120000,36, 100000,@ERROR OUTPUT
   SELECT @ERROR
GO

/*
3.	Tạo SP cập nhật trường NgaySinh cho các nhân viên (thủ tục có hai tham số đầu vào gồm mã nhân viên, Ngaysinh).
Nếu không tìm thấy bản ghi cần cập nhật trả ra giá trị 0. Ngược lại, cho phép cập nhật.
*/
GO
CREATE PROC SP_SUA_NS_NV
                   ( @MANV NVARCHAR(4),
                     @NGAYSINH DATETIME,
                     @KQ INT OUTPUT
                    )
AS
   BEGIN
      IF(NOT EXISTS(SELECT * FROM tblNhanVien WHERE MANV=@MANV))
		SET @KQ=0
      ELSE
         BEGIN
			UPDATE tblNhanVien SET NgaySinh=@NGAYSINH WHERE MaNV=@MANV
		 SET @KQ=1
		 END
       RETURN @KQ
   END
GO
---TEST        
   DECLARE @ERROR INT
   EXEC SP_SUA_NS_NV 'NV05','2/9/2000',@ERROR OUTPUT
   SELECT @ERROR
   SELECT * FROM tblNhanVien
GO

/*
4.	Tạo thủ tục có
Đầu vào: NgayCong1, NgayCong2
Đầu ra: tổng số nhân viên trong cơ quan có So ngay lam viec trong khoảng Ngaycong1 và NgayCong2.
*/
GO
CREATE PROC SP_NGAY_CONG
                   ( @NGAYCONG1 INT,
                     @NGAYCONG2 INT,
                     @KQ INT OUTPUT
                    )
AS
   BEGIN
      SET @KQ = (SELECT COUNT(*) FROM tblNhanVien WHERE NgayCong BETWEEN @NGAYCONG1 AND @NGAYCONG2)
       RETURN @KQ
   END
GO
---TEST        
   DECLARE @ERROR INT
   EXEC SP_NGAY_CONG 25,30 ,@ERROR OUTPUT
   SELECT @ERROR
   SELECT * FROM tblNhanVien
GO
/*
5.	Tạo thủ tục có
Đầu vào: TenCV
Đầu ra: tổng số lượng nhân viên co chuc vu này.
*/
GO
CREATE PROC SP_DEM_CHUC_VU
                   ( @TENCV NVARCHAR(30),
                     @KQ INT OUTPUT
                    )
AS
   BEGIN
      SET @KQ = (SELECT COUNT(*) FROM tblNhanVien WHERE MaCV =(SELECT MaCV FROM tblChucvu WHERE TenCV=@TENCV))
       RETURN @KQ
   END
GO
---TEST        
   DECLARE @ERROR INT
   EXEC SP_DEM_CHUC_VU N'Vệ Sinh' ,@ERROR OUTPUT
   SELECT @ERROR
   SELECT * FROM tblNhanVien
GO
