import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính Sách Riêng Tư'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1),
                    const Color(0xFF21CBF3).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chính Sách Riêng Tư Gym Pro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật lần cuối: 22 tháng 8, 2025',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              title: '1. Giới Thiệu',
              content:
                  '''Chào mừng bạn đến với Gym Pro, ứng dụng quản lý thể dục toàn diện của bạn. Chúng tôi cam kết bảo vệ quyền riêng tư của bạn và đảm bảo tính bảo mật của thông tin cá nhân. Chính Sách Riêng Tư này giải thích cách chúng tôi thu thập, sử dụng, bảo vệ và chia sẻ thông tin của bạn khi sử dụng ứng dụng di động và các dịch vụ liên quan.

Bằng cách sử dụng Gym Pro, bạn đồng ý với việc thu thập và sử dụng thông tin theo Chính Sách Riêng Tư này. Nếu bạn không đồng ý với các chính sách và thực tiễn của chúng tôi, vui lòng không sử dụng dịch vụ của chúng tôi.''',
            ),

            // Information We Collect
            _buildSection(
              title: '2. Thông Tin Chúng Tôi Thu Thập',
              content:
                  '''Chúng tôi thu thập nhiều loại thông tin để cung cấp và cải thiện dịch vụ:

**2.1 Thông Tin Cá Nhân**
- Thông Tin Tài Khoản: Họ tên đầy đủ, địa chỉ email
- Chi Tiết Liên Hệ: Số điện thoại, địa chỉ
- Chi Tiết Cá Nhân: Ngày sinh, giới tính
- Thông Tin Hồ Sơ: Ảnh đại diện, mục tiêu thể dục, sở thích

**2.2 Thông Tin Thu Thập Tự Động**
- Thông Tin Thiết Bị: Loại thiết bị, hệ điều hành, mã định danh thiết bị duy nhất
- Dữ Liệu Sử Dụng: Tương tác ứng dụng, sử dụng tính năng, thời lượng phiên
- Dữ Liệu Kỹ Thuật: Địa chỉ IP, loại trình duyệt, phiên bản ứng dụng
- Dữ Liệu Vị Trí: Thông tin vị trí chung (với sự cho phép của bạn)

**2.3 Thông Tin Từ Bên Thứ Ba**
- Mạng Xã Hội: Nếu bạn kết nối tài khoản mạng xã hội
- Thiết Bị Thể Dục: Dữ liệu từ máy theo dõi thể dục hoặc thiết bị đeo được kết nối
- Phân Tích: Thống kê sử dụng ẩn danh và báo cáo lỗi''',
            ),

            // How We Use Information
            _buildSection(
              title: '3. Cách Chúng Tôi Sử Dụng Thông Tin Của Bạn',
              content:
                  '''Chúng tôi sử dụng thông tin của bạn cho các mục đích sau:

**3.1 Cung Cấp Dịch Vụ**
- Tạo và quản lý tài khoản người dùng của bạn
- Cung cấp đề xuất thể dục cá nhân hóa
- Theo dõi tiến trình tập luyện và thành tích của bạn
- Kích hoạt các tính năng xã hội và tương tác cộng đồng

**3.2 Giao Tiếp**
- Gửi thông báo dịch vụ quan trọng
- Cung cấp hỗ trợ và trợ giúp khách hàng
- Chia sẻ mẹo thể dục và nội dung giáo dục
- Thông báo về cập nhật ứng dụng và tính năng mới

**3.3 Cải Thiện và Phân Tích**
- Phân tích việc sử dụng ứng dụng để cải thiện trải nghiệm người dùng
- Phát triển tính năng và dịch vụ mới
- Tiến hành nghiên cứu và phân tích
- Sửa lỗi và các vấn đề kỹ thuật

**3.4 An Toàn và Bảo Mật**
- Ngăn chặn gian lận và lạm dụng
- Bảo vệ chống lại các mối đe dọa bảo mật
- Tuân thủ các yêu cầu pháp lý
- Đảm bảo tính toàn vẹn của nền tảng''',
            ),

            // Data Sharing
            _buildSection(
              title: '4. Chia Sẻ và Tiết Lộ Thông Tin',
              content:
                  '''Chúng tôi không bán, trao đổi hoặc cho thuê thông tin cá nhân của bạn cho bên thứ ba. Chúng tôi có thể chia sẻ thông tin của bạn trong các trường hợp hạn chế sau:

**4.1 Nhà Cung Cấp Dịch Vụ**
Chúng tôi làm việc với các nhà cung cấp dịch vụ bên thứ ba đáng tin cậy hỗ trợ chúng tôi vận hành ứng dụng:
- Nhà cung cấp lưu trữ đám mây (Google Firebase)
- Dịch vụ phân tích (báo cáo lỗi, phân tích sử dụng)
- Dịch vụ giao tiếp (email, thông báo đẩy)

**4.2 Yêu Cầu Pháp Lý**
Chúng tôi có thể tiết lộ thông tin của bạn nếu được yêu cầu bởi pháp luật hoặc với thiện chí tin rằng việc tiết lộ như vậy là cần thiết để:
- Tuân thủ các thủ tục pháp lý hoặc yêu cầu của chính phủ
- Bảo vệ quyền, tài sản hoặc sự an toàn của chúng tôi
- Ngăn chặn gian lận hoặc hoạt động bất hợp pháp
- Thực thi Điều khoản Dịch vụ của chúng tôi

**4.3 Chuyển Giao Kinh Doanh**
Trong trường hợp sáp nhập, mua lại hoặc bán tài sản, thông tin của bạn có thể được chuyển giao như một phần của giao dịch kinh doanh.''',
            ),

            // Data Security
            _buildSection(
              title: '5. Bảo Mật và Bảo Vệ Dữ Liệu',
              content:
                  '''Chúng tôi thực hiện các biện pháp kỹ thuật và tổ chức thích hợp để bảo vệ thông tin cá nhân của bạn:

**5.1 Các Biện Pháp Bảo Vệ Kỹ Thuật**
- Mã hóa dữ liệu khi truyền tải và lưu trữ
- Hệ thống xác thực an toàn
- Đánh giá và cập nhật bảo mật thường xuyên
- Kiểm soát truy cập và giám sát

**5.2 Các Biện Pháp Bảo Vệ Tổ Chức**
- Đào tạo nhân viên về bảo mật dữ liệu
- Các chính sách và quy trình bảo mật nghiêm ngặt
- Kiểm tra quyền truy cập thường xuyên
- Kế hoạch ứng phó sự cố

Tuy nhiên, không có phương pháp truyền tải qua internet hoặc lưu trữ điện tử nào là 100% an toàn. Chúng tôi không thể đảm bảo tuyệt đối về tính bảo mật.

**5.3 Lưu Trữ Dữ Liệu**
Chúng tôi chỉ giữ lại thông tin cá nhân của bạn trong thời gian cần thiết để:
- Cung cấp dịch vụ cho bạn
- Tuân thủ các nghĩa vụ pháp lý
- Giải quyết tranh chấp và thực thi thỏa thuận
- Duy trì hồ sơ kinh doanh theo yêu cầu

Khi thông tin không còn cần thiết, chúng tôi sẽ xóa an toàn hoặc ẩn danh hóa.''',
            ),

            // User Rights
            _buildSection(
              title: '6. Quyền và Lựa Chọn Của Bạn',
              content:
                  '''Bạn có một số quyền liên quan đến thông tin cá nhân của mình:

**6.1 Truy Cập và Khả Năng Chuyển Đổi**
- Xem và tải xuống dữ liệu cá nhân của bạn
- Yêu cầu bản sao thông tin của bạn ở định dạng di động
- Truy cập lịch sử xử lý dữ liệu của bạn

**6.2 Sửa Chữa và Cập Nhật**
- Cập nhật thông tin hồ sơ của bạn bất cứ lúc nào
- Sửa chữa dữ liệu không chính xác hoặc không đầy đủ
- Yêu cầu xác minh độ chính xác của dữ liệu

**6.3 Xóa và Hạn Chế**
- Xóa tài khoản và dữ liệu liên quan của bạn
- Yêu cầu hạn chế xử lý dữ liệu
- Từ chối một số việc sử dụng dữ liệu nhất định

**6.4 Tùy Chọn Giao Tiếp**
- Quản lý cài đặt thông báo
- Hủy đăng ký khỏi thông tin tiếp thị
- Kiểm soát tùy chọn chia sẻ dữ liệu

Để thực hiện những quyền này, vui lòng liên hệ với chúng tôi thông qua cài đặt ứng dụng hoặc các kênh hỗ trợ của chúng tôi.''',
            ),

            // International Transfers
            _buildSection(
              title: '7. Chuyển Giao Dữ Liệu Quốc Tế',
              content:
                  '''Dịch vụ của chúng tôi được cung cấp toàn cầu, và thông tin của bạn có thể được xử lý ở các quốc gia khác ngoài nơi bạn cư trú. Chúng tôi đảm bảo sự bảo vệ đầy đủ thông qua:

- Các điều khoản hợp đồng tiêu chuẩn được phê duyệt bởi các cơ quan quản lý
- Quyết định về tính đầy đủ cho một số quốc gia nhất định
- Chương trình chứng nhận và quy tắc doanh nghiệp ràng buộc
- Sự đồng ý rõ ràng của bạn khi được yêu cầu

Chúng tôi duy trì cùng mức độ bảo vệ bất kể dữ liệu của bạn được xử lý ở đâu.''',
            ),

            // Children's Privacy
            _buildSection(
              title: '8. Quyền Riêng Tư Trẻ Em',
              content:
                  '''Gym Pro không dành cho trẻ em dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin cá nhân từ trẻ em dưới 13 tuổi. Nếu bạn là cha mẹ hoặc người giám hộ và tin rằng con bạn đã cung cấp thông tin cá nhân cho chúng tôi, vui lòng liên hệ với chúng tôi ngay lập tức.

Đối với người dùng từ 13-18 tuổi, chúng tôi khuyến nghị sự giám sát và hướng dẫn của cha mẹ khi sử dụng dịch vụ của chúng tôi. Chúng tôi đặc biệt quan tâm đến việc bảo vệ quyền riêng tư của người dùng trẻ tuổi.''',
            ),

            // Changes to Policy
            _buildSection(
              title: '9. Thay Đổi Chính Sách Riêng Tư Này',
              content:
                  '''Chúng tôi có thể cập nhật Chính Sách Riêng Tư này theo thời gian để phản ánh những thay đổi trong thực tiễn, công nghệ, yêu cầu pháp lý hoặc các yếu tố khác của chúng tôi. Khi chúng tôi thực hiện thay đổi:

- Chúng tôi sẽ thông báo cho bạn thông qua ứng dụng hoặc qua email
- Ngày "Cập nhật lần cuối" sẽ được sửa đổi
- Những thay đổi quan trọng sẽ được hiển thị nổi bật
- Việc tiếp tục sử dụng được coi là chấp nhận chính sách đã cập nhật

Chúng tôi khuyến khích bạn xem lại Chính Sách Riêng Tư này định kỳ để được thông báo về cách chúng tôi bảo vệ thông tin của bạn.''',
            ),

            // Contact Information
            _buildSection(
              title: '10. Liên Hệ Với Chúng Tôi',
              content:
                  '''Nếu bạn có câu hỏi, quan ngại hoặc yêu cầu liên quan đến Chính Sách Riêng Tư này hoặc các thực tiễn dữ liệu của chúng tôi, vui lòng liên hệ:

**Email:** privacy@gympro.app
**Địa chỉ:** Đội Riêng Tư Gym Pro, 123 Fitness Street, Health City, HC 12345
**Điện thoại:** +1 (555) 123-4567

Để được hỗ trợ ngay lập tức về các vấn đề riêng tư, bạn cũng có thể liên hệ với chúng tôi thông qua tính năng hỗ trợ trong ứng dụng.

Chúng tôi cam kết giải quyết các mối quan ngại về quyền riêng tư của bạn một cách nhanh chóng và hiệu quả.''',
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Cảm ơn bạn đã tin tưởng Gym Pro trong hành trình thể dục của mình.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quyền riêng tư của bạn là ưu tiên hàng đầu của chúng tôi.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF2196F3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
