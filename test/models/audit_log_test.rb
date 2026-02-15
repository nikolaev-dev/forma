require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:audit_log).valid?
  end

  test "invalid without action" do
    assert_not build(:audit_log, action: nil).valid?
  end

  test "invalid without actor_user" do
    assert_not build(:audit_log, actor_user: nil).valid?
  end

  test ".log! creates audit log entry" do
    admin = create(:user, role: "admin")
    tag = create(:tag)

    log = AuditLog.log!(actor: admin, action: "tag.create", record: tag, after: { name: tag.name })

    assert log.persisted?
    assert_equal "tag.create", log.action
    assert_equal admin, log.actor_user
    assert_equal "Tag", log.record_type
    assert_equal tag.id, log.record_id
  end

  test "scope recent orders by created_at desc" do
    admin = create(:user, role: "admin")
    old = AuditLog.log!(actor: admin, action: "old.action")
    old.update_column(:created_at, 1.day.ago)
    recent = AuditLog.log!(actor: admin, action: "new.action")

    assert_equal recent, AuditLog.recent.first
  end

  test "scope for_record filters by polymorphic record" do
    admin = create(:user, role: "admin")
    tag = create(:tag)
    AuditLog.log!(actor: admin, action: "tag.create", record: tag)
    AuditLog.log!(actor: admin, action: "style.create")

    assert_equal 1, AuditLog.for_record(tag).count
  end
end
