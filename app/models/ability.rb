class Ability
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    @user = user

    if user.super_admin
      admin_abilities
    else
      if user.roles.empty? 
        user_abilities
      else
        user.roles.each do |role|
          case role.name
          when 'admin'
            admin_abilities
          when 'student'
            student_abilities
          when 'teacher'
            teacher_abilities
          when 'project_manager'
            pm_abilities
          when 'curator'
            curator_abilities
          end
        end
      end
    end
  end

# =======================================
  def user_abilities
    can :read, Field
  end
# =======================================

  def admin_abilities
    can :manage, :all
  end

  def common_abilities
    can :read, Field
    UserAssignment.all.each do |user_assignment|
      if user_assignment.user_id == user.id
        can :read, user_assignment.assignmentable
      end
    end
    can :read, Forum, Wiki
  end

  def curator_abilities
    common_abilities
    can :update, Field, curator_id: user.id
    can :manage, [Project, Course] do |obj|
      obj.field.curator_id == user.id
    end
    can :update, UserAnswer, recipient_id: user.id
  end

  def teacher_abilities
    common_abilities
    can :manage, Issue do |issue|
      issue.issuable.type == "Course" && issue.issuable.teacher_id == user.id
    end
    can :update, UserAnswer, recipient_id: user.id
  end

  def pm_abilities
    common_abilities
    can :manage, Project, project_manager_id: user.id
    can :manage, Issue do |issue|
      issue.issuable.type == "Project" && issue.issuable.project_manager_id == user.id
    end
    can :update, UserAnswer, recipient_id: user.id
  end

  def student_abilities
    common_abilities
    can :create, UserAnswer
  end
end
