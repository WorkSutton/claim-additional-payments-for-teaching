module MathsAndPhysics
  class EligibilityAdminAnswersPresenter
    include Admin::PresenterMethods

    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    # Formats the eligibility as a list of questions and answers.
    # Suitable for playback to the service operators for them to review
    # the claim.
    #
    # Returns an array. Each element of this an array is an array of two
    # elements:
    # [0]: short question text;
    # [1]: answer text;
    def answers
      [].tap do |a|
        a << teaching_maths_or_physics
        a << current_school
        a << initial_teacher_training_subject
        a << initial_teacher_training_subject_specialism if eligibility.initial_teacher_training_subject_specialism.present?
        a << has_uk_maths_or_physics_degree if eligibility.has_uk_maths_or_physics_degree.present?
        a << qts_award_year
        a << employed_as_supply_teacher
        a << has_entire_term_contract if eligibility.has_entire_term_contract.present?
        a << employed_directly if eligibility.employed_directly.present?
        a << disciplinary_action
        a << formal_performance_action
      end
    end

    private

    def teaching_maths_or_physics
      [
        translate("maths_and_physics.admin.teaching_maths_or_physics"),
        (eligibility.teaching_maths_or_physics? ? "Yes" : "No")
      ]
    end

    def current_school
      [
        translate("admin.current_school"),
        display_school(eligibility.current_school)
      ]
    end

    def initial_teacher_training_subject
      [
        translate("maths_and_physics.admin.initial_teacher_training_subject"),
        translate("maths_and_physics.answers.initial_teacher_training_subject.#{eligibility.initial_teacher_training_subject}")
      ]
    end

    def initial_teacher_training_subject_specialism
      [
        translate("maths_and_physics.admin.initial_teacher_training_subject_specialism"),
        translate("maths_and_physics.answers.initial_teacher_training_subject_specialism.#{eligibility.initial_teacher_training_subject_specialism}")
      ]
    end

    def has_uk_maths_or_physics_degree
      [
        translate("maths_and_physics.admin.has_uk_maths_or_physics_degree"),
        degree_answer
      ]
    end

    def qts_award_year
      [
        translate("admin.qts_award_year"),
        eligibility.qts_award_year_answer
      ]
    end

    def employed_as_supply_teacher
      [
        translate("maths_and_physics.admin.employed_as_supply_teacher"),
        (eligibility.employed_as_supply_teacher? ? "Yes" : "No")
      ]
    end

    def has_entire_term_contract
      [
        translate("maths_and_physics.admin.has_entire_term_contract"),
        (eligibility.has_entire_term_contract? ? "Yes" : "No")
      ]
    end

    def employed_directly
      [
        translate("maths_and_physics.admin.employed_directly"),
        translate("maths_and_physics.answers.employed_directly.#{eligibility.employed_directly? ? "yes" : "no"}")
      ]
    end

    def disciplinary_action
      [
        translate("maths_and_physics.admin.disciplinary_action"),
        (eligibility.subject_to_disciplinary_action? ? "Yes" : "No")
      ]
    end

    def formal_performance_action
      [
        translate("maths_and_physics.admin.formal_performance_action"),
        (eligibility.subject_to_formal_performance_action? ? "Yes" : "No")
      ]
    end

    def degree_answer
      case eligibility.has_uk_maths_or_physics_degree
      when "yes" then "Yes"
      when "no" then "No"
      else translate("maths_and_physics.answers.has_uk_maths_or_physics_degree.#{eligibility.has_uk_maths_or_physics_degree}")
      end
    end
  end
end
