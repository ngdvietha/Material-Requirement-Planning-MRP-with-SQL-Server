USE [B8_HTAuto_VN]
GO
/****** Object:  StoredProcedure [dbo].[usp_Vcd_MRP_detail]    Script Date: 12/22/2023 11:10:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[usp_Vcd_MRP_detail]
  @_DocDate1 date	= 'Jan 01 2014' ,
  @_DocDate2 date	= 'Dec 31 2014', 
  @_NCC NVARCHAR(24) = '',
  @_SubNhom NVARCHAR(24) = '',
  @_NhaCungCap NVARCHAR(24) = '',
  @_TenCot1 date = 'Dec 31 2014'  OUTPUT,
  @_TenCot2 date = 'Dec 31 2014' OUTPUT,
  @_TenCot3 date = 'Dec 31 2014' OUTPUT,
  @_TenCot4 date = 'Dec 31 2014' OUTPUT,
  @_TenCot5 date = 'Dec 31 2014' OUTPUT,
  @_TenCot6 date = 'Dec 31 2014' OUTPUT,
  @_TenCot7 date = 'Dec 31 2014' OUTPUT,
  @_TenCot8 date = 'Dec 31 2014' OUTPUT,
  @_TenCot9 date = 'Dec 31 2014' OUTPUT,
  @_TenCot10 date = 'Dec 31 2014' OUTPUT,
  @_TenCot11 date = 'Dec 31 2014' OUTPUT,
  @_TenCot12 date = 'Dec 31 2014' OUTPUT,
  @_TenCot13 date = 'Dec 31 2014' OUTPUT,
  @_StringCopy1 NVARCHAR(MAX) = '' 

	
AS
BEGIN
	SET NOCOUNT ON;

	-- Chỉnh lại 2 biến docdate1 và docdate2
	SET @_DocDate2 =
		CASE
			WHEN DAY(@_DocDate2) <= 15 THEN DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2) , 1)
			ELSE DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2) , 16)
		END

	DECLARE @_DocDate01 Date
		SET @_DocDate01 = DATEADD(MONTH, 12, @_DocDate2)

		SET @_DocDate01 =
		CASE
			WHEN DAY(@_DocDate01) <= 15 THEN DATEFROMPARTS(YEAR(@_DocDate01), MONTH(@_DocDate01) , 15)
			ELSE EOMONTH(@_DocDate01)
		END


	-- Tạo cấu trúc bảng tạm để lưu dữ liệu
	IF Object_Id(N'tempdb..#V_CtTmp0') IS NOT NULL DROP TABLE #V_CtTmp0
	SELECT TOP 0 
		ItemCode, 
		CAST ('' AS nvarchar(64)) AS MaChung,
		CAST ('' AS nvarchar(120)) AS ItemName,
		CAST ('' AS nvarchar(MAX)) AS MauXe,
		CAST ('' AS nvarchar(64)) AS PhanLoaiHang,
		CAST ('' AS nvarchar(64)) AS Ma_TrongDiem,
		CAST ('' AS nvarchar(64)) AS NCC,
		CAST ('' AS nvarchar(64)) AS ItemCatgCode,
		CAST ('' AS nvarchar(64)) AS BCG,
		CAST ('' AS nvarchar(64)) AS PhanBo1,
		CAST ('' AS nvarchar(64)) AS PhanBo2,
		CAST ('' AS nvarchar(64)) AS PhanBo3
	INTO #V_CtTmp0
	FROM B00CtTmp

	--Tạo bảng tạm chứa dữ liệu mới nhất về phân bổ
	DECLARE @_LatestDate date
	SELECT  @_LatestDate = MAX(DocDate) FROM B30BizDocPhanboBrand

	DROP TABLE IF EXISTS #V_CtTmpPb
	SELECT
		ItemCatgCode,
		ManufacturerCode,
		Tyle_pb,
		Phanbo1,
		Phanbo2,
		Phanbo3 into #V_CtTmpPb
	FROM B30BizDocPhanboBrand
	WHERE DocDate = @_LatestDate


	--Việt hà thêm leadtime của Nhà cung cấp
		--Tạo bảng tạm chứa leadtime theo cập nhập mới nhất
	DROP TABLE IF EXISTS #V_CtTmpleadtime
	SELECT * into #V_CtTmpleadtime FROM (
	SELECT 
		a.Leadtime [Loại Leadtime],
		b.CustomerCode, 
		ManufacturerCode, 
		IIF(c.ItemCatgCode = 'TY', 'ALL', c.ItemCatgCode) ItemCatgCode,
		a.CreatedAt,
		b.LEADTIME,
		ROW_NUMBER() OVER(PARTITION BY
		a.Leadtime,
		b.CustomerCode, 
		ManufacturerCode, 
		ItemGroupCode
		ORDER BY a.CreatedAt DESC
		) SoThuTu
	FROM B30BizDoc a	
	INNER JOIN B30BizDocTableLeadtime b ON a.BizDocId = b.BizDocId
	LEFT JOIN B20ItemGroup c ON b.ItemGroupCode = c.Code
	WHERE DocCode = 'LT' AND a.IsActive = 1) a
	WHERE a.SoThuTu = 1

	--Lấy dữ liệu cơ bản của vật tư và insert vào bảng tạm
	INSERT INTO #V_CtTmp0 (ItemCode, MaChung, ItemName,MauXe,Ma_TrongDiem, PhanLoaiHang,NCC,ItemCatgCode,BCG, PhanBo1, PhanBo2, PhanBo3)
	SELECT 
		a.Code,
		--COALESCE(d.CustomerCode, d.CustomerCOde) NhaCungCap,
		a.Ma_Sin1,
		a."Name",
		b.Name2,
		a.Ma_TrongDiem,
		a.ClassCode1,
		b.ManufacturerCode,
		a.ItemCatgCode,
		Classify_BCG,
		ISNULL(Phanbo1, 1) Phanbo1,
		ISNULL(Phanbo2, 1) Phanbo2,
		ISNULL(Phanbo3, 1) Phanbo3
	FROM B20Item a
	LEFT JOIN B20ItemInfo b ON a.Code = b.ItemCode
	LEFT JOIN #V_CtTmpPb c ON b.ManufacturerCode = c.ManufacturerCode AND a.ItemCatgCode = c.ItemCatgCode
	--LEFT JOIN #V_CtTmpleadtime d ON (d.ManufacturerCode = b.ManufacturerCode AND d.ItemCatgCode = 'ALL') OR (d.ManufacturerCode = b.ManufacturerCode AND d.ItemCatgCode = a.ItemCatgCode)
	--LEFT JOIN #V_CtTmpleadtime e ON e.ManufacturerCode = b.ManufacturerCode AND e.ItemCatgCode = a.ItemCatgCode
	WHERE a.Isactive = 1 AND Ma_khac <> 'KHONGNHAP'
	AND a.ItemCatgCode NOT IN ('DAUNUOCMAT','DICHVU','PHUGIA','QUATANG','THUNGCARTON','VPP-VTDG')
	AND ItemGroupCode <> 'VIN' AND ClassCode1 IN (2)


	-- tiem xử lý tìm kiếm chuỗi vật tư
   IF ISNULL(@_NCC,'') <> ''
   BEGIN
   DELETE #V_CtTmp0 WHERE NCC <> @_NCC
   END
   IF ISNULL(@_SubNhom,'') <> ''
   BEGIN
   DELETE #V_CtTmp0 WHERE SubNhom <> @_SubNhom
   END
   

	IF OBJECT_ID('TempDb..#Temp1') IS NOT NULL DROP TABLE #Temp1
	CREATE TABLE #Temp1 (ItemCode NVARCHAR(24), PID INT)
	
	IF OBJECT_ID('TempDb..#KetQua') IS NOT NULL DROP TABLE #KetQua
	CREATE TABLE #KetQua (ItemCode NVARCHAR(24), PID INT)

	DECLARE @_ItemCodeTmp NVARCHAR(1000), @_ViTri1 Int, @_DoDaiChuoi1 Int, @_i INT
		
	IF ISNULL(@_StringCopy1, '') <> ''
	BEGIN
		SET @_DoDaiChuoi1 = LEN(@_StringCopy1)
    
		IF LEN(@_StringCopy1) > 0 AND CHARINDEX(CHAR(13), @_StringCopy1) = 0
		BEGIN
			INSERT INTO #Temp1 (ItemCode)
			VALUES (@_StringCopy1)
		END
        
		SET @_i = 1
		WHILE CHARINDEX(CHAR(13), @_StringCopy1) > 0
		BEGIN
			SET @_ViTri1 = CHARINDEX(CHAR(13), @_StringCopy1)
			SET @_ItemCodeTmp = LTRIM(RTRIM(SUBSTRING(@_StringCopy1, 1, @_ViTri1-1)))
			SET @_StringCopy1 = SUBSTRING(@_StringCopy1, @_ViTri1 + 2, @_DoDaiChuoi1)
                
			INSERT INTO #Temp1 (ItemCode, PID)
				VALUES (@_ItemCodeTmp, @_i)
            
			IF LEN(@_StringCopy1) > 0 AND CHARINDEX(CHAR(13), @_StringCopy1) = 0
			BEGIN
				SET @_i = @_i + 1
				INSERT INTO #Temp1 (ItemCode, PID)
				VALUES (@_StringCopy1, @_i)
			END
			SET @_i = @_i + 1
		END
		
		INSERT INTO #KetQua
		SELECT ItemCode, PID
			FROM #Temp1
			GROUP BY ItemCode, PID


	DELETE #V_CtTmp0 WHERE ItemCode NOT IN (SELECT ItemCode FROM #KetQua)
	END


----------------------------------------------------------
	--Lấy dữ liệu tồn hiện tại
	DROP TABLE IF EXISTS #V_CtTmpTon

	SELECT b.Ma_Sin1, c.ManufacturerCode, b.ClassCode1,SUM(Quantity_Ton) Quantity_Ton INTO #V_CtTmpTon FROM (
	SELECT ItemCode, SUM(Quantity) AS Quantity_Ton FROM B30OpenInventory
	WHERE IsActive = 1 AND Year =YEAR(GETDATE())
	GROUP BY ItemCode
	UNION ALL
	SELECT  ItemCode, SUM(CASE WHEN DocGroup = 1 THEN Quantity ELSE -Quantity END) AS Quantity_Ton FROM B30StockLedger
	WHERE IsActive = 1 AND DocDate BETWEEN DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AND GETDATE() --Year(DocDate) =YEAR(GETDATE())
	GROUP BY ItemCode) a
	LEFT JOIN B20Item b ON a.ItemCode = b.Code
	LEFT JOIN B20ItemInfo c ON a.ItemCode = c.ItemCode
	GROUP BY b.Ma_Sin1, c.ManufacturerCode, b.ClassCode1

	--Thêm cột và update dữ liệu tồn vào trong bảng tạm
	ALTER TABLE #V_CtTmp0
	ADD Ton_Hien_Tai numeric(15,4)

	--Thêm dữ liệu tồn mã thay thế 
	UPDATE #V_CtTmp0
	SET Ton_Hien_Tai = ISNULL(b.Quantity_Ton,0)
	FROM #V_CtTmp0 a
	LEFT JOIN #V_CtTmpTon b ON a.MaChung = b.Ma_Sin1 AND a.NCC = b.ManufacturerCode AND b.ClassCode1 = 2
	WHERE a.PhanLoaiHang = 2
	


----------------------------------------------
	-- Lấy dữ liệu minstock
	DROP TABLE IF EXISTS #V_CtTmpMinStock

	SELECT a.Ma_Sin1, b.ManufacturerCode, a.ClassCode1, SUM(Minstock) Minstock into #V_CtTmpMinStock
	FROM B20Item a
	LEFT JOIN B20ItemInfo b ON a.Code = b.ItemCode
	WHERE a.Isactive = 1 AND Ma_khac <> 'KHONGNHAP'
	AND ItemCatgCode NOT IN ('DAUNUOCMAT','DICHVU','PHUGIA','QUATANG','THUNGCARTON','VPP-VTDG')
	AND ItemGroupCode <> 'VIN' AND ClassCode1 IN (1,2)
	GROUP BY a.Ma_Sin1, b.ManufacturerCode, a.ClassCode1

	--Thêm cột dữ liệu minstock 
	ALTER TABLE #V_CtTmp0
	ADD MinstockNew numeric(15,4)

	--Thêm dữ liệu Minstock mã thay thế 
	UPDATE #V_CtTmp0
	SET MinstockNew = ISNULL(b.Minstock,0)
	FROM #V_CtTmp0 a
	LEFT JOIN #V_CtTmpMinStock b ON a.MaChung = b.Ma_Sin1 AND a.NCC = b.ManufacturerCode AND b.ClassCode1 = 2
	WHERE a.PhanLoaiHang = 2




	-- Lấy số lượng bán +  chaycua
  IF Object_Id(N'tempdb..#V_CtTmpb') IS NOT NULL DROP TABLE #V_CtTmpb
  SELECT TOP 0 Itemcode, CAST(0 AS NUMERIC (15,4)) AS Quantity_ban INTO #V_CtTmpb FROM B00CtTmp

  INSERT INTO #V_CtTmpb (ItemCode,Quantity_ban)

  SELECT  ItemCode, SUM(CASE WHEN DocGroup = 1 THEN -Quantity ELSE Quantity END) AS Quantity_ban FROM B30StockLedger
  WHERE IsActive = 1 AND DocCode IN ('HD','TL') AND DocDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND GETDATE()
  GROUP BY ItemCode

  UNION ALL 
  SELECT ItemCode, SUM(Quantity)  FROM B30AccDocPurchase ct0 INNER JOIN B30AccDoc Ct ON ct0.Stt = Ct.Stt
  where Ct.IsActive = 1 AND Ct.DocStatus <> '9' AND ct.DocCode='NM' AND ItemCode LIKE 'HT%' AND ct0.Notes <> 'KHONGCOMA' AND Ct.DocDate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND GETDATE()
  GROUP BY ItemCode

  -----------------------------------------------------------------
  --Thêm cột như cầu bán tb tháng
  SELECT 
	  b.Ma_Sin1, 
	  b.ClassCode1, 
	  c.ManufacturerCode, 
	  SUM(Quantity_ban) Quantity_ban,
	  SUM(Quantity_ban)/6 Quantity_ban_tb into #V_CtTmpb2
  FROM #V_CtTmpb a
  LEFT JOIN B20Item b ON a.ItemCode = b.Code
  LEFT JOIN B20ItemInfo c ON a.ItemCode = c.ItemCode
  GROUP BY b.Ma_Sin1, b.ClassCode1, c.ManufacturerCode

  ALTER TABLE #V_CtTmp0
  ADD Quantity_ban_tb NUMERIC (15,4)



  	--Thêm dữ liệu bán mã thay thế 
	UPDATE #V_CtTmp0
	SET Quantity_ban_tb = ISNULL(b.Quantity_ban_tb,0)
	FROM #V_CtTmp0 a
	LEFT JOIN #V_CtTmpb2 b ON a.MaChung = b.Ma_Sin1 AND a.NCC = b.ManufacturerCode AND b.ClassCode1 = 2
	WHERE a.PhanLoaiHang = 2
	


	--Nhân thêm chỉ số tăng trường vào cột nhu cầu
	UPDATE #V_CtTmp0
	SET Quantity_ban_tb = 
	CASE 
		WHEN BCG ='Hangpheu' THEN 1.15* Quantity_ban_tb
	   	WHEN BCG ='SUPER_XA' THEN 0
		WHEN BCG ='Hang_duy_tri' THEN 1.1* Quantity_ban_tb
		WHEN BCG ='Hang_dang_phat_trien' THEN 1.05* Quantity_ban_tb 
		ELSE Quantity_ban_tb 
	END;

	-- a tiềm note: các trường trên cần nhân với tỷ lệ của hằng nữa:
	-- bảng B30BizDocPhanboBrand join B30BizDoc where DocCode = 'BB'

	--Xử lý nhân tỷ lệ vào tồn hiện tại, minstock new và quantity_ban_tb

	


	--Tạo bảng lưu tổng tồn, minstock và số lượng bán theo mã chung
	DROP TABLE IF EXISTS #V_CtTmpTotal
	SELECT
		MaChung,
		SUM(Ton_Hien_Tai) Ton_Hien_Tai,
		SUM(MinstockNew) MinstockNew,
		SUM(Quantity_ban_tb) Quantity_ban_tb into #V_CtTmpTotal
	FROM #V_CtTmp0
	GROUP BY MaChung



	--Update các cột tồn, minstock và quantity bán theo mã chung 
	UPDATE #V_CtTmp0
	SET 
		Ton_Hien_Tai = b.Ton_Hien_Tai
	FROM #V_CtTmp0 a
	LEFT JOIN #V_CtTmpTotal b ON a.MaChung = b.MaChung
	WHERE a.PhanBo3 = 1

	



	UPDATE #V_CtTmp0
	SET 
		MinstockNew = b.MinstockNew
	FROM #V_CtTmp0 a
	LEFT JOIN #V_CtTmpTotal b ON a.MaChung = b.MaChung
	WHERE a.Phanbo2 = 1


	UPDATE #V_CtTmp0
	SET 
		Quantity_ban_tb = b.Quantity_ban_tb
	FROM #V_CtTmp0 a
	LEFT JOIN #V_CtTmpTotal b ON a.MaChung = b.MaChung
	WHERE a.Phanbo1 = 1



	--Nhân thêm tỉ lệ vào trong số lượng bán
	UPDATE #V_CtTmp0
	SET
		Quantity_ban_tb = CASE WHEN b.Tyle_pb IS NULL THEN a.Quantity_ban_tb ELSE a.Quantity_ban_tb * b.Tyle_pb END
	FROM #V_CtTmp0 a
	LEFT JOIN #V_CtTmpPb b ON b.ItemCatgCode = a.ItemCatgCode AND b.ManufacturerCode = a.NCC

	--Tạo bảng daterange dynamic
	DECLARE @_index int = 1

	DECLARE @_startdate date = DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2), 1)

	DROP TABLE IF EXISTS #DateRange
	CREATE TABLE #DateRange (DatePra date, Index_number int)

	WHILE @_index <> 14
	BEGIN
		INSERT INTO #DateRange
		VALUES
		(@_startdate, @_index)
		SET @_startdate = DATEADD(MONTH, 1, @_startdate)
		SET @_index = @_index + 1
	END

	ALTER TABLE #DateRange
	ALTER COLUMN Index_number nvarchar(25)

	--Tạo biến ngày nhỏ nhất
	DECLARE @_MinDate date
	SET @_MinDate = (SELECT MIN(DatePra) FROM #DateRange)

	--Tạo bảng và insert dữ liệu về BO cho hàng không phân bổ
	DROP TABLE IF EXISTS #CtmpBO
		--Tạo bảng tạm lưu số lượng đặt
	DROP TABLE IF EXISTS #CTE1

	SELECT
		b.BizDocId,
		ItemCode,
		SUM(Quantity) SL_đặt into #CTE1 
	FROM B30BizDocDetailPO a
	LEFT JOIN B30BizDoc b ON a.BizDocId = b.BizDocId
	WHERE b.Isactive = 1 
	AND a.BizDocId IN 
		(SELECT BizDocId FROM B30Bizdoc
			WHERE Isactive = 1 AND DocCode = 'PO' AND DocStatus IN (4,5))
	GROUP BY b.BizDocId, ItemCode, a.CustomerCode

	--		SELECT *  FROM #CTE1
	--return

		--Tạo bảng tạm lưu số lượng về
	DROP TABLE IF EXISTS #CTE2

	SELECT 
		BizDocId_PO,
		ItemCode, 
		SUM(Quantity) SL_về into #CTE2
	FROM B30AccDocPurchase a
	WHERE a.Isactive = 1 AND a.DocCode IN ('NK', 'NM') 
	AND a.Stt IN 
		(SELECT Stt FROM B30AccDoc 
			WHERE Isactive = 1 AND a.DocCode IN ('NK', 'NM') 
			AND (DocStatus NOT IN (0) OR (DocStatus IN (0) AND (ETA IS NOT NULL OR ATA IS NOT NULL)))) 
	AND BizDocId_PO IN 
	(SELECT BizDocId FROM B30Bizdoc
			WHERE Isactive = 1 AND DocCode = 'PO' AND DocStatus IN (4,5))
	GROUP BY ItemCode, BizDocId_PO
	


	SELECT
		e.EstimatedDeliveryDate,
		c.Ma_Sin1,
		d.ManufacturerCode,
		ISNULL(SUM(SL_đặt),0) - ISNULL(SUM(SL_về),0) SL_BO into #CtmpBO
	FROM #CTE1 a
		LEFT JOIN #CTE2 b ON a.ItemCode = b.ItemCode AND a.BizDocId = b.BizDocId_PO
		LEFT JOIN B30BizDoc e ON a.BizDocId = e.BizDocId
		LEFT JOIN B20Item c ON a.ItemCode = c.Code
		LEFT JOIN B20ItemInfo d ON a.ItemCode = d.ItemCode
	WHERE c.ClassCode1 = 2 
	GROUP BY e.EstimatedDeliveryDate,c.Ma_Sin1, d.ManufacturerCode, c.ClassCode1
	HAVING ISNULL(SUM(SL_đặt),0) - ISNULL(SUM(SL_về),0) > 0

	--Tạo cột BO_before
	ALTER TABLE #V_CtTmp0
	ADD BO_before numeric(10,2)

	UPDATE #V_CtTmp0
	SET
		BO_before = ISNULL(b.SL_BO,0)
	FROM #V_CtTmp0 a
	INNER JOIN (SELECT Ma_Sin1, ManufacturerCode, SUM(SL_BO) SL_BO FROM #CtmpBO WHERE EstimatedDeliveryDate < @_MinDate GROUP BY Ma_Sin1, ManufacturerCode) b 
	ON a.NCC = b.ManufacturerCode AND a.MaChung = b.Ma_Sin1 AND a.PhanBo3 = 2

	UPDATE #V_CtTmp0
	SET
		BO_before = ISNULL(b.SL_BO,0)
	FROM #V_CtTmp0 a
	INNER JOIN (SELECT Ma_Sin1, SUM(SL_BO) SL_BO FROM #CtmpBO WHERE EstimatedDeliveryDate < @_MinDate GROUP BY Ma_Sin1) b 
	ON  a.MaChung = b.Ma_Sin1 AND a.PhanBo3 = 1



	-- DROP hai bảng tạm trung gian trên
	DROP TABLE #CTE1
	DROP TABLE #CTE2


	--Update lại trường date của bảng BO
	UPDATE #CtmpBO
		SET EstimatedDeliveryDate =
				CASE 
					WHEN DAY(EstimatedDeliveryDate) < 15 THEN DATEFROMPARTS(YEAR(EstimatedDeliveryDate), MONTH(EstimatedDeliveryDate), 1)
					ELSE DATEFROMPARTS(YEAR(DATEADD(MONTH, 1, EstimatedDeliveryDate)), MONTH(DATEADD(MONTH, 1, EstimatedDeliveryDate)), 1) 
				END
				

	--Tạo bảng tạm chứa BO theo mã chung để sau join cho mã hàng có phân bổ 1
	DROP TABLE IF EXISTS #CtmpBOPhanBo
	SELECT
		EstimatedDeliveryDate,
		Ma_Sin1,
		SUM(SL_BO) SL_BO into #CtmpBOPhanBo
	FROM #CtmpBO
	GROUP BY EstimatedDeliveryDate, Ma_Sin1

	 
	---------------------------------------------------------
	--Tạo bảng tạm chứa hàng chờ về
	--Lấy giá trị hàng chờ về
	DROP TABLE IF EXISTS #V_CtTmpHCV;
	
	DROP TABLE IF EXISTS #ScheduleReceipt
	SELECT 
		Stt, 
		ItemCode, 
		SUM(Quantity) SL_đang_về into #ScheduleReceipt
	FROM B30AccDocPurchase a
	WHERE a.Isactive = 1 AND a.DocCode = 'NK' 
	AND a.Stt IN 
		(SELECT Stt FROM B30AccDoc 
			WHERE Isactive = 1 AND DocCode = 'NK' 
			AND ((DocStatus IN (1,0) AND (ETA IS NOT NULL OR ATA IS NOT NULL)))
			) 
	AND BizDocId_PO IN 
	(SELECT BizDocId FROM B30Bizdoc
			WHERE Isactive = 1 AND DocCode = 'PO' AND DocStatus IN (4,5))
	GROUP BY Stt,ItemCode

	DROP TABLE IF EXISTS #V_CtTmpHCV
	SELECT 
		c.MaChung Ma_Sin1, 
		c.NCC ManufacturerCode,
		CAST(COALESCE(ATA, ETA) AS date) ScheduleReceiptDate, 
		ISNULL(SUM(a.SL_đang_về),0) ScheduleReceiptQuantity into #V_CtTmpHCV
	FROM #ScheduleReceipt a
	LEFT JOIN B30AccDoc b ON a.Stt = b.Stt
	LEFT JOIN #V_CtTmp0 c ON c.ItemCode = a.ItemCode
	WHERE c.PhanLoaiHang = 2
	GROUP BY c.MaChung, c.NCC ,c.PhanLoaiHang,CAST(COALESCE(ATA, ETA) AS date)

	--Add cột HCV trước đó
	ALTER TABLE #V_CtTmp0
	ADD HCV_before numeric(10,2)


	UPDATE #V_CtTmp0
	SET
		HCV_before = ISNULL(b.ScheduleReceiptQuantity,0)
	FROM #V_CtTmp0 a
	INNER JOIN (SELECT Ma_Sin1, ManufacturerCode, SUM(ScheduleReceiptQuantity) ScheduleReceiptQuantity FROM #V_CtTmpHCV WHERE ScheduleReceiptDate < @_MinDate GROUP BY Ma_Sin1, ManufacturerCode) b 
	ON a.NCC = b.ManufacturerCode AND a.MaChung = b.Ma_Sin1 AND a.PhanBo3 = 2

	UPDATE #V_CtTmp0
	SET
		HCV_before = ISNULL(b.ScheduleReceiptQuantity,0)
	FROM #V_CtTmp0 a
	INNER JOIN (SELECT Ma_Sin1, SUM(ScheduleReceiptQuantity) ScheduleReceiptQuantity FROM #V_CtTmpHCV WHERE ScheduleReceiptDate < @_MinDate GROUP BY Ma_Sin1) b 
	ON a.MaChung = b.Ma_Sin1 AND a.PhanBo3 = 1

	--Sửa cột tháng sao cho #V_CtTmpHCV để sau còn pivot
	UPDATE #V_CtTmpHCV
		SET ScheduleReceiptDate =
				CASE 
					WHEN DAY(ScheduleReceiptDate) < 15 THEN DATEFROMPARTS(YEAR(ScheduleReceiptDate), MONTH(ScheduleReceiptDate), 1)
					ELSE DATEFROMPARTS(YEAR(DATEADD(MONTH, 1, ScheduleReceiptDate)), MONTH(DATEADD(MONTH, 1, ScheduleReceiptDate)), 1) 
				END	


	--Thêm một bảng HCV cho hàng phân bổ
	DROP TABLE IF EXISTS #V_CtTmpHCVPhanBo
	SELECT 
	Ma_Sin1,
	ScheduleReceiptDate,
	SUM(ScheduleReceiptQuantity) ScheduleReceiptQuantity into #V_CtTmpHCVPhanBo
	FROM #V_CtTmpHCV
	GROUP BY Ma_Sin1,ScheduleReceiptDate

	----------------------------------------------------------------------- Tính toán MRP
	--Declare các biến cần thiết
	DECLARE @End_id date 
		SELECT @End_id = MAX(DatePra) FROM #DateRange

	DECLARE @Start_id date
		SELECT @Start_id = MIN(DatePra) FROM #DateRange
	--Tạo bảng tồn để tính MRP
	DROP TABLE IF EXISTS #V_CtTmpTonMrp
	CREATE TABLE #V_CtTmpTonMrp (Stt nvarchar(24), ItemCode nvarchar(64), TonMRP numeric(15,4))

	INSERT INTO #V_CtTmpTonMrp
	SELECT @Start_id  Stt, ItemCode, Ton_Hien_Tai + ISNULL(BO_before,0) + ISNULL(HCV_before,0) TonMRP FROM #V_CtTmp0

	--Tạo bảng kết quả về tồn dự kiến
	DROP TABLE IF EXISTS #V_CtTmpTonDuKien
	CREATE TABLE #V_CtTmpTonDuKien (Stt nvarchar(24), ItemCode nvarchar(64), TonDuKien numeric(15,4))

	--Tạo vòng lặp để tính toán tồn dự kiến và insert vào bảng tạm

	WHILE @Start_id <> DATEADD(MONTH, 1, @End_id)
	BEGIN 
		INSERT INTO #V_CtTmpTonDuKien
		SELECT 
			DATEADD(MONTH,1,@Start_id) Stt,
			a.ItemCode,
			CASE
				WHEN c.PhanBo3 = 2 THEN a.TonMRP + ISNULL(b.ScheduleReceiptQuantity,0) + ISNULL(e.SL_BO,0) - c.Quantity_ban_tb
				WHEN c.PhanBo3 = 1 THEN a.TonMRP + ISNULL(d.ScheduleReceiptQuantity,0) + ISNULL(f.SL_BO,0) - c.Quantity_ban_tb 
			END TonDuKien
		FROM #V_CtTmpTonMrp a
			LEFT JOIN #V_CtTmp0 c ON c.ItemCode = a.ItemCode
			LEFT JOIN #V_CtTmpHCV b ON c.MaChung = b.Ma_Sin1 
										AND a.Stt = b.ScheduleReceiptDate 
										AND c.NCC = b.ManufacturerCode 
										AND c.PhanBo3 = 2
			LEFT JOIN #V_CtTmpHCVPhanBo d
							ON d.Ma_Sin1 = c.MaChung
							AND a.Stt = d.ScheduleReceiptDate
							AND c.PhanBo3 = 1
			LEFT JOIN #CtmpBO e ON e.Ma_Sin1 = c.MaChung
									AND a.Stt = e.EstimatedDeliveryDate
									AND e.ManufacturerCode = c.NCC
									AND c.PhanBo3 = 2
			LEFT JOIN #CtmpBOPhanBo f ON f.Ma_Sin1 = c.MaChung
											AND a.Stt = f.EstimatedDeliveryDate
											AND c.PhanBo3 = 1

		UPDATE #V_CtTmpTonMrp
			SET Stt = DATEADD(MONTH, 1, @Start_id)

		UPDATE #V_CtTmpTonMrp
			SET TonMRP = IIF( b.TonDuKien < 0, 0, b.TonDuKien)
		FROM #V_CtTmpTonMrp a
		LEFT JOIN #V_CtTmpTonDuKien b ON a.ItemCode = b.ItemCode AND a.Stt = b.Stt

		SET @Start_id = DATEADD(MONTH, 1, @Start_id)

	END
	
	--Delete giá trị thừa của bảng tạm tồn dự kiến
	DELETE FROM #V_CtTmpTonDuKien
	WHERE Stt = DATEADD(MONTH, 1, @End_id)

	--Nối lại bảng và update lại cột theo Stt cố định để đưa lên Bravo
		--Nối lại bảng HCV
		DROP TABLE IF EXISTS #V_CtTmpHCVTong
		SELECT * into #V_CtTmpHCVTong
		FROM (
		SELECT ScheduleReceiptDate, b.ItemCode, a.ScheduleReceiptQuantity
		FROM #V_CtTmpHCV a
		INNER JOIN #V_CtTmp0 b ON a.Ma_Sin1 = b.MaChung AND a.ManufacturerCode = b.NCC AND PhanBo3 = 2

		UNION ALL

		SELECT ScheduleReceiptDate, b.ItemCode, a.ScheduleReceiptQuantity
		FROM #V_CtTmpHCVPhanBo a
		INNER JOIN #V_CtTmp0 b ON a.Ma_Sin1 = b.MaChung  AND PhanBo3 = 1
		) a

		--Update lại giá trị của cột date thành cố định để pivot
		ALTER TABLE #V_CtTmpHCVTong
		ALTER COLUMN ScheduleReceiptDate nvarchar(100)

		UPDATE #V_CtTmpHCVTong
			SET ScheduleReceiptDate = CONCAT('HCV_',b.Index_number)
		FROM #V_CtTmpHCVTong a
		LEFT JOIN #DateRange b ON a.ScheduleReceiptDate = b.DatePra

		--Nối lại bảng BO
		DROP TABLE IF EXISTS #V_CtTmpBOTong
		SELECT * into #V_CtTmpBOTong
		FROM (
		SELECT EstimatedDeliveryDate, b.ItemCode, a.SL_BO
		FROM #CtmpBO a
		INNER JOIN #V_CtTmp0 b ON a.Ma_Sin1 = b.MaChung AND a.ManufacturerCode = b.NCC AND PhanBo3 = 2

		UNION ALL

		SELECT EstimatedDeliveryDate, b.ItemCode, a.SL_BO
		FROM #CtmpBOPhanBo a
		INNER JOIN #V_CtTmp0 b ON a.Ma_Sin1 = b.MaChung  AND PhanBo3 = 1
		) a

		--Update lại giá trị của cột date thành cố định để pivot
		ALTER TABLE #V_CtTmpBOTong
		ALTER COLUMN EstimatedDeliveryDate nvarchar(100)

		UPDATE #V_CtTmpBOTong
			SET EstimatedDeliveryDate = CONCAT('BO_',b.Index_number)
		FROM #V_CtTmpBOTong a
		LEFT JOIN #DateRange b ON a.EstimatedDeliveryDate = b.DatePra

		--Update lại giá trị cột tồn dự kiến để pivot
		UPDATE #V_CtTmpTonDuKien
			SET Stt = CONCAT('TonDuKien_',b.Index_number)
		FROM #V_CtTmpTonDuKien a
		LEFT JOIN #DateRange b ON a.Stt = b.DatePra

	---------------------------------------------------------------------------Pivot tất cả các bảng tổng ra để tiến hành join
	--Pivot bảng HCV
	UPDATE #DateRange
		SET Index_number = CONCAT('HCV_', Index_number)

	DROP TABLE IF EXISTS ##V_CtTmpHCVpivot
	DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
	DECLARE @ColumnName AS NVARCHAR(MAX)
 
	SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
		   + QUOTENAME(Index_number)
	FROM (SELECT Index_number FROM #DateRange ORDER BY DatePra ASC OFFSET 0 ROWS) AS Courses
	
	SET @DynamicPivotQuery = 
	  N'SELECT ItemCode, ' + @ColumnName + ' into ##V_CtTmpHCVpivot
		FROM #V_CtTmpHCVTong
		PIVOT(SUM(ScheduleReceiptQuantity) 
			  FOR ScheduleReceiptDate IN (' + @ColumnName + ')) AS PVTTable'
	--Execute the Dynamic Pivot Query
	EXEC sp_executesql @DynamicPivotQuery

	--Pivot bảng BO
	UPDATE #DateRange
		SET Index_number = REPLACE(Index_number, 'HCV', 'BO')

	DROP TABLE IF EXISTS ##V_CtTmpBOpivot
	DECLARE @DynamicPivotQuery2 AS NVARCHAR(MAX)
	DECLARE @ColumnName2 AS NVARCHAR(MAX)
 
	SELECT @ColumnName2= ISNULL(@ColumnName2 + ',','') 
		   + QUOTENAME(Index_number)
	FROM (SELECT Index_number FROM #DateRange ORDER BY DatePra ASC OFFSET 0 ROWS) AS Courses
	
	SET @DynamicPivotQuery2 = 
	  N'SELECT ItemCode, ' + @ColumnName2 + ' into ##V_CtTmpBOpivot
		FROM #V_CtTmpBOTong
		PIVOT(SUM(SL_BO) 
			  FOR EstimatedDeliveryDate IN (' + @ColumnName2 + ')) AS PVTTable'
	--Execute the Dynamic Pivot Query
	EXEC sp_executesql @DynamicPivotQuery2

	--Pivot bảng TonDuKien
	UPDATE #DateRange
	SET Index_number = REPLACE(Index_number, 'BO', 'TonDuKien')

	DROP TABLE IF EXISTS ##V_CtTmpMRPpivot
	DECLARE @DynamicPivotQuery3 AS NVARCHAR(MAX)
	DECLARE @ColumnName3 AS NVARCHAR(MAX)
 
	SELECT @ColumnName3= ISNULL(@ColumnName3 + ',','') 
		   + QUOTENAME(Index_number)
	FROM (SELECT Index_number FROM #DateRange ORDER BY DatePra ASC OFFSET 0 ROWS) AS Courses
	
	SET @DynamicPivotQuery3 = 
	  N'SELECT ItemCode, ' + @ColumnName3 + ' into ##V_CtTmpMRPpivot
		FROM #V_CtTmpTonDuKien
		PIVOT(SUM(TonDuKien) 
			  FOR Stt IN (' + @ColumnName3 + ')) AS PVTTable'
	--Execute the Dynamic Pivot Query
	EXEC sp_executesql @DynamicPivotQuery3



	--SELECT lại ra bảng final
	DROP TABLE IF EXISTS #V_CtTmpFinal
	SELECT
	h.CustomerCode NhaCungCap,
	a.*,
	HCV_1,
	HCV_2,
	HCV_3,
	HCV_4,
	HCV_5,
	HCV_6,
	HCV_7,
	HCV_8,
	HCV_9,
	HCV_10,
	HCV_11,
	HCV_12,
	HCV_13,
	BO_1,
	BO_2,
	BO_3,
	BO_4,
	BO_5,
	BO_6,
	BO_7,
	BO_8,
	BO_9,
	BO_10,
	BO_11,
	BO_12,
	BO_13,
	TonDuKien_2,
	TonDuKien_3,
	TonDuKien_4,
	TonDuKien_5,
	TonDuKien_6,
	TonDuKien_7,
	TonDuKien_8,
	TonDuKien_9,
	TonDuKien_10,
	TonDuKien_11,
	TonDuKien_12,
	TonDuKien_13 into #V_CtTmpFinal
	FROM #V_CtTmp0 a
	LEFT JOIN ##V_CtTmpHCVpivot c ON c.ItemCode = a.ItemCode
	LEFT JOIN ##V_CtTmpBOpivot d ON d.ItemCode = a.ItemCode
	LEFT JOIN ##V_CtTmpMRPpivot e ON e.ItemCode = a.ItemCode
	LEFT JOIN #V_CtTmpleadtime h ON (h.ManufacturerCode = a.NCC AND h.ItemCatgCode = 'ALL') OR (h.ManufacturerCode = a.NCC AND h.ItemCatgCode = a.ItemCatgCode)


	--Thêm hai cột leadtime stock và leadtime, NCC
	ALTER TABLE #V_CtTmpFinal
	ADD Leadtime_NK DECIMAL(10,2)

	ALTER TABLE #V_CtTmpFinal
	ADD Leadtime_Stock DECIMAL(10,2)

	--Update leadtime đối với trường hợp cột leadtime dài
	UPDATE #V_CtTmpFinal
	SET Leadtime_NK = COALESCE(b.Leadtime, c.Leadtime)
	FROM #V_CtTmpFinal a
	LEFT JOIN #V_CtTmpleadtime b ON a.NhaCungCap = b.CustomerCode AND a.NCC = b.ManufacturerCode AND b.ItemCatgCode = 'ALL' AND b.[Loại Leadtime]= 01
	LEFT JOIN #V_CtTmpleadtime c ON a.NhaCungCap = b.CustomerCode AND a.NCC = b.ManufacturerCode AND b.ItemCatgCode = a.ItemCatgCode AND b.[Loại Leadtime]= 01

	--Update leadtime đối với trường hợp cột leadtime stock
	UPDATE #V_CtTmpFinal
	SET Leadtime_Stock = COALESCE(b.Leadtime, c.Leadtime)
	FROM #V_CtTmpFinal a
	LEFT JOIN #V_CtTmpleadtime b ON a.NhaCungCap = b.CustomerCode AND a.NCC = b.ManufacturerCode AND b.ItemCatgCode = 'ALL' AND b.[Loại Leadtime]= 02
	LEFT JOIN #V_CtTmpleadtime c ON a.NhaCungCap = b.CustomerCode AND a.NCC = b.ManufacturerCode AND b.ItemCatgCode = a.ItemCatgCode AND b.[Loại Leadtime]= 02


	--Set biến tên cột
	UPDATE #DateRange
		SET Index_number = REPLACE(Index_number, 'TonDuKien_', '')
	SET @_TenCot1 = (SELECT TOP 1 DatePra FROM #DateRange ORDER BY DatePra ASC)
	SET @_TenCot2 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 2)
	SET @_TenCot3 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 3)
	SET @_TenCot4 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 4)
	SET @_TenCot5 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 5)
	SET @_TenCot6 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 6)
	SET @_TenCot7 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 7)
	SET @_TenCot8 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 8)
	SET @_TenCot9 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 9)
	SET @_TenCot10 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 10)
	SET @_TenCot11 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 11)
	SET @_TenCot12 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 12)
	SET @_TenCot13 = (SELECT TOP 1 DatePra FROM #DateRange WHERE Index_number = 13)

	SELECT * FROM #V_CtTmpFinal



	DROP TABLE #ScheduleReceipt
	DROP TABLE  #V_CtTmp0
	DROP TABLE  #V_CtTmpTon
	DROP TABLE  #V_CtTmpMinStock
	DROP TABLE  #V_CtTmpb
	DROP TABLE  #V_CtTmpb2
	DROP TABLE #V_CtTmpPb
	DROP TABLE #V_CtTmpTotal
	DROP TABLE #CtmpBO
	DROP TABLE #CtmpBOPhanBo
	DROP TABLE #V_CtTmpHCV
	DROP TABLE #V_CtTmpHCVPhanBo
	DROP TABLE #V_CtTmpHCVTong
	DROP TABLE #DateRange
	DROP TABLE #V_CtTmpBOTong
	DROP TABLE #V_CtTmpTonDuKien
	DROP TABLE #V_CtTmpTonMrp
	DROP TABLE ##V_CtTmpBOpivot
	DROP TABLE ##V_CtTmpHCVpivot
	DROP TABLE ##V_CtTmpMRPpivot
	DROP TABLE #V_CtTmpleadtime
END
--GO
--EXEC usp_Vcd_MRP_detail @_DocDate2='2023-11-30'