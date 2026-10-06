# 示例 profiledef.sh 修改
iso_name="NanbuOS"
iso_label="NANBUOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="NanbuOS <https://example.com>"
iso_application="NanbuOS is still a test operating system for now"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"