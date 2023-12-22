# Material-Requirement-Planning-MRP-with-SQL-Server
<h1>Sơ lược về lý thuyết MRP</h1>
Material Requirement Planning – MRP là quy trình hoạch định nhu cầu nguyên vật liệu cần thiết cho quá trình sản xuất hoặc mua hàng. Hiểu đơn giản thì đây là hệ thống giúp tính toán nguyên vật liệu cần thiết để hoàn thành đơn hàng của khách hàng.</br></br>
Dưới đây là một bảng tính toán MRP cơ bản, dựa vào các yếu tố về tồn kho, hàng đang về, nhu cầu, leadtime của NCC để từ đó dự báo về ngày hết tồn và sẽ đặt tiếp theo (Planned Release)</br>

![image](https://github.com/ngdvietha/Material-Requirement-Planning-MRP-with-SQL-Server/assets/71718604/8603d595-f7d9-4e09-9247-f519aefa39e8)
</br>

<h1>Chu trình chạy MRP trong doanh nghiệp HTAUTO</h1>
Dữ liệu sẽ chủ yếu lấy từ database <strong>B8_HTAuto_VN</strong> </br> 
Link file backup: https://drive.google.com/file/d/1gumAdxOE8tw64j7VWwFQBaXx0AyWV64c/view?usp=sharing</br></br>
Link luồng file drawio:
https://drive.google.com/file/d/1E3Lf_MCGsjqGzNhudW3ICGRgk8twbNtZ/view?usp=sharing </br></br>

Tóm tắt về quá trình tạo bảng MRP từ code SQL server:
- Dữ liệu sẽ được lấy từ database B8_HTAuto_VN
- Define logic tính toán, một số logic phức tạp của doanh nghiệp HTAUTO cần chú ý, các mã có cùng mã chung sẽ có thể thay thế được cho nhau, và do vậy nên sẽ có chỉ số phân như bảng dưới (vì có những hàng chất lượng cao thì có thể tính theo nhu cầu của cả mã chung đó, có những thì phải xét hẹp đi là mã chung và hãng gì)

![image](https://github.com/ngdvietha/Material-Requirement-Planning-MRP-with-SQL-Server/assets/71718604/5614d589-855d-4a1e-a6b7-55e66412cfa1)

- Logic tính toán được đóng gói lại trong câu code tạo thủ tục [dbo].[usp_Vcd_MRP_detail] trong database B8_HTAuto_VN. <Strong>Xem file SQL</Strong> để biết thêm chi tiết, câu EXECUTE thủ tục được comment và để ở cuối
- Sample outfile trong SQL và trên phầm mềm được thể hiện ở <Strong>2 file excel</Strong>

![MRP flow drawio](https://github.com/ngdvietha/Material-Requirement-Planning-MRP-with-SQL-Server/assets/71718604/bc9718d8-3a7a-4f6c-9b19-e94a3622dbf2)
