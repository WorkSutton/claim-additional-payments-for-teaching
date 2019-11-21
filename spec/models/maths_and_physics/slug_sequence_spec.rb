require "rails_helper"

RSpec.describe MathsAndPhysics::SlugSequence do
  let(:claim) { build(:claim, eligibility: build(:maths_and_physics_eligibility)) }

  subject(:slug_sequence) { MathsAndPhysics::SlugSequence.new(claim) }

  describe "The sequence as defined by #slugs" do
    it "excludes “has-uk-maths-or-physics-degree” if the claimant's initial teacher training specialised in maths or physics" do
      claim.eligibility.initial_teacher_training_specialised_in_maths_or_physics = true

      expect(slug_sequence.slugs).not_to include("has-uk-maths-or-physics-degree")
    end

    it "excludes the remaining supply teacher slugs if the claimant is not employed as a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("entire-term-contract")
      expect(slug_sequence.slugs).not_to include("employed-directly")
    end

    it "excludes the “address” slug if any address fields were acquired from GOV.UK Verify" do
      claim.verified_fields = []
      expect(slug_sequence.slugs).to include("address")

      claim.verified_fields = ["postcode"]
      expect(slug_sequence.slugs).to_not include("address")
    end

    it "excludes the “gender” slug if the claim's payroll_gender were acquired supplied by GOV.UK Verify" do
      claim.verified_fields = []
      expect(slug_sequence.slugs).to include("gender")

      claim.verified_fields = ["payroll_gender"]
      expect(slug_sequence.slugs).to_not include("gender")
    end

    it "excludes student loan plan slugs if the claimant is not paying off a student loan" do
      claim.has_student_loan = false
      expect(slug_sequence.slugs).not_to include("student-loan-country")
      expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).not_to include("student-loan-start-date")

      claim.has_student_loan = true
      expect(slug_sequence.slugs).to include("student-loan-country")
      expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).to include("student-loan-start-date")
    end

    it "excludes the remaining student loan plan slugs if the claimant received their student loan in a Plan 1 country" do
      claim.has_student_loan = true

      StudentLoan::PLAN_1_COUNTRIES.each do |plan_1_country|
        claim.student_loan_country = plan_1_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).not_to include("student-loan-start-date")
      end

      %w[england wales].each do |variable_plan_country|
        claim.student_loan_country = variable_plan_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).to include("student-loan-start-date")
      end
    end
  end
end
