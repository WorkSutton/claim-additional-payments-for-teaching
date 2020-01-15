require "rails_helper"

RSpec.describe Claim, type: :model do
  context "that has a teacher_reference_number" do
    it "validates the length of the teacher reference number" do
      expect(build(:claim, teacher_reference_number: "1/2/3/4/5/6/7")).to be_valid
      expect(build(:claim, teacher_reference_number: "1/2/3/4/5")).not_to be_valid
      expect(build(:claim, teacher_reference_number: "12/345678")).not_to be_valid
    end
  end

  context "that has a email address" do
    it "validates that the value is in the correct format" do
      expect(build(:claim, email_address: "notan email@address.com")).not_to be_valid
      expect(build(:claim, email_address: "name@example.com")).to be_valid
      expect(build(:claim, email_address: "")).to be_valid
    end

    it "checks that the email address in not longer than 256 characters" do
      expect(build(:claim, email_address: "#{"e" * 256}@example.com")).not_to be_valid
    end
  end

  context "that has a National Insurance number" do
    it "validates that the National Insurance number is in the correct format" do
      expect(build(:claim, national_insurance_number: "12 34 56 78 C")).not_to be_valid
      expect(build(:claim, national_insurance_number: "QQ 11 56 78 DE")).not_to be_valid

      expect(build(:claim, national_insurance_number: "QQ 34 56 78 C")).to be_valid
    end
  end

  context "that has a first name" do
    it "validates the length of name is 100 characters or less" do
      expect(build(:claim, first_name: "Name " * 50)).not_to be_valid
      expect(build(:claim, first_name: "John")).to be_valid
    end
  end

  context "that has a middle name" do
    it "validates the length of middle name is 100 characters or less" do
      expect(build(:claim, middle_name: "Name " * 50)).not_to be_valid
      expect(build(:claim, middle_name: "Arnold")).to be_valid
    end
  end

  context "that has a surname" do
    it "validates the length of surname is 100 characters or less" do
      expect(build(:claim, surname: "Name " * 50)).not_to be_valid
      expect(build(:claim, surname: "Kimble")).to be_valid
    end
  end

  context "that has a postcode" do
    it "validates the length of postcode is not greater than 11" do
      expect(build(:claim, postcode: "M12345 23453WD")).not_to be_valid
      expect(build(:claim, postcode: "M1 2WD")).to be_valid
    end
  end

  context "that has an address" do
    it "validates the length of each address line is not greater than 100 characters" do
      %i[address_line_1 address_line_2 address_line_3 address_line_4].each do |attribute_name|
        expect(build(:claim, attribute_name => "X" + "ABCD" * 25)).not_to be_valid
        expect(build(:claim, attribute_name => "ABCD" * 25)).to be_valid
      end
    end
  end

  context "that has bank details" do
    it "validates the format of bank_account_number and bank_sort_code" do
      expect(build(:claim, bank_account_number: "ABC12 34 56 789")).not_to be_valid
      expect(build(:claim, bank_account_number: "12-34-56-78-90")).not_to be_valid
      expect(build(:claim, bank_account_number: "12-34-56-78")).to be_valid
      expect(build(:claim, bank_account_number: "12-34-56")).not_to be_valid

      expect(build(:claim, bank_sort_code: "ABC12 34 567")).not_to be_valid
      expect(build(:claim, bank_sort_code: "12 34 56")).to be_valid
    end

    it "validates the format of the building society roll number" do
      expect(build(:claim, building_society_roll_number: "CXJ-K6 897/98X")).to be_valid
      expect(build(:claim, building_society_roll_number: "123456789/ABCD")).to be_valid
      expect(build(:claim, building_society_roll_number: "123456789")).to be_valid

      expect(build(:claim, building_society_roll_number: "123456789/ABC.CD-EFGH ")).not_to be_valid
      expect(build(:claim, building_society_roll_number: "123456789/*****")).not_to be_valid
    end

    context "on save" do
      it "strips out white space and the “-” character from bank_account_number and bank_sort_code" do
        claim = build(:claim, bank_sort_code: "12 34 56", bank_account_number: "12-34-56-78")
        claim.save!

        expect(claim.bank_sort_code).to eql("123456")
        expect(claim.bank_account_number).to eql("12345678")
      end

      it "strips spaces from and upcases the National Insurance number" do
        claim = build(:claim, national_insurance_number: "qq 34 56 78 c")
        claim.save!

        expect(claim.national_insurance_number).to eq("QQ345678C")
      end
    end
  end

  context "that has a student loan plan" do
    it "validates the plan" do
      expect(build(:claim, student_loan_plan: StudentLoan::PLAN_1)).to be_valid

      expect { build(:claim, student_loan_plan: "plan_42") }.to raise_error(ArgumentError)
    end
  end

  it "is not submittable without a value for the student_loan_plan present" do
    expect(build(:claim, :submittable, student_loan_plan: nil)).not_to be_valid(:submit)
    expect(build(:claim, :submittable, student_loan_plan: Claim::NO_STUDENT_LOAN)).to be_valid(:submit)
  end

  it "is submittable with optional student loan questions not answered" do
    claim = build(
      :claim,
      :submittable,
      has_student_loan: false,
      student_loan_plan: Claim::NO_STUDENT_LOAN,
      student_loan_country: nil,
      student_loan_courses: nil,
      student_loan_start_date: nil
    )

    expect(claim).to be_valid(:submit)
  end

  it "triggers validations on the eligibility appropriate to the context" do
    claim = build(:claim)

    expect(claim).not_to be_valid(:"qts-year")
    expect(claim.errors.values).to include(["Select whether you completed your initial teacher training before or after September 2013"])
  end

  context "when saving in the “gender” validation context" do
    it "validates the presence of gender" do
      expect(build(:claim)).not_to be_valid(:gender)
      expect(build(:claim, payroll_gender: :male)).to be_valid(:gender)
    end
  end

  context "when saving in the name validation context" do
    it "validates the presence of the first_name and surname attributes" do
      expect(build(:claim)).not_to be_valid(:name)
      expect(build(:claim, first_name: "Cheryl")).not_to be_valid(:name)
      expect(build(:claim, surname: "Lynn")).not_to be_valid(:name)

      expect(build(:claim, first_name: "Cheryl", surname: "Lynn")).to be_valid(:name)
    end
  end

  context "when saving in the “address” validation context" do
    it "validates the presence of address_line_1 and postcode" do
      expect(build(:claim)).not_to be_valid(:address)

      valid_address_attributes = {address_line_1: "123 Main Street", postcode: "12345"}
      expect(build(:claim, valid_address_attributes)).to be_valid(:address)
    end
  end

  context "when saving in the “date-of-birth” validation context" do
    it "validates the presence of date_of_birth" do
      expect(build(:claim)).not_to be_valid(:"date-of-birth")
      expect(build(:claim, date_of_birth: Date.new(2000, 2, 1))).to be_valid(:"date-of-birth")
    end
  end

  context "when saving in the “teacher-reference-number” validation context" do
    it "validates the presence of teacher_reference_number" do
      expect(build(:claim)).not_to be_valid(:"teacher-reference-number")
      expect(build(:claim, teacher_reference_number: "1234567")).to be_valid(:"teacher-reference-number")
    end
  end

  context "when saving in the “national-insurance-number” validation context" do
    it "validates the presence of national_insurance_number" do
      expect(build(:claim)).not_to be_valid(:"national-insurance-number")
      expect(build(:claim, national_insurance_number: "QQ123456C")).to be_valid(:"national-insurance-number")
    end
  end

  context "when saving in the “student-loan” validation context" do
    it "validates the presence of student_loan" do
      expect(build(:claim)).not_to be_valid(:"student-loan")
      expect(build(:claim, has_student_loan: true)).to be_valid(:"student-loan")
      expect(build(:claim, has_student_loan: false)).to be_valid(:"student-loan")
    end
  end

  context "when saving in the “student-loan-country” validation context" do
    it "validates the presence of student_loan_country" do
      expect(build(:claim)).not_to be_valid(:"student-loan-country")
      expect(build(:claim, student_loan_country: :england)).to be_valid(:"student-loan-country")
    end
  end

  context "when saving in the “student-loan-how-many-courses” validation context" do
    it "validates the presence of the student_loan_how_many_courses" do
      expect(build(:claim)).not_to be_valid(:"student-loan-how-many-courses")
      expect(build(:claim, student_loan_courses: :one_course)).to be_valid(:"student-loan-how-many-courses")
    end
  end

  context "when saving in the “student-loan-start-date” validation context" do
    it "validates the presence of the student_loan_start_date" do
      expect(build(:claim, student_loan_courses: :one_course)).not_to be_valid(:"student-loan-start-date")
      expect(build(:claim, student_loan_start_date: StudentLoan::BEFORE_1_SEPT_2012)).to be_valid(:"student-loan-start-date")
    end

    it "the validation error message is pluralized or not based on student_loan_how_many_courses" do
      claim = build(:claim, student_loan_courses: :one_course)
      claim.valid?(:"student-loan-start-date")
      expect(claim.errors[:student_loan_start_date]).to eq [I18n.t("validation_errors.student_loan_start_date.#{claim.student_loan_courses}")]

      claim = build(:claim, student_loan_courses: :two_or_more_courses)
      claim.valid?(:"student-loan-start-date")
      expect(claim.errors[:student_loan_start_date]).to eq [I18n.t("validation_errors.student_loan_start_date.#{claim.student_loan_courses}")]
    end
  end

  context "when saving in the “email-address” validation context" do
    it "validates the presence of email_address" do
      expect(build(:claim)).not_to be_valid(:"email-address")
      expect(build(:claim, email_address: "name@example.tld")).to be_valid(:"email-address")
    end
  end

  context "when saving in the “bank-details” validation context" do
    it "validates that the bank_account_number and bank_sort_code are present" do
      invalid_claim = build(:claim)
      valid_claim = build(:claim, bank_sort_code: "123456", bank_account_number: "87654321", banking_name: "Jo Bloggs")
      expect(invalid_claim).not_to be_valid(:"bank-details")
      expect(valid_claim).to be_valid(:"bank-details")
    end
  end

  context "when saving in the “submit” validation context" do
    it "validates the claim is in a submittable state" do
      expect(build(:claim)).not_to be_valid(:submit)
      expect(build(:claim, :submittable)).to be_valid(:submit)
    end

    it "validates the claim’s eligibility" do
      ineligible_claim = build(:claim, :submittable)
      ineligible_claim.eligibility.mostly_performed_leadership_duties = true

      expect(ineligible_claim).not_to be_valid(:submit)
      expect(ineligible_claim.errors.messages[:base]).to include("You’re not eligible for this payment")
    end
  end

  describe "#teacher_reference_number" do
    let(:claim) { build(:claim, teacher_reference_number: teacher_reference_number) }

    context "when the teacher reference number is stored and contains non digits" do
      let(:teacher_reference_number) { "12\\23 /232 " }
      it "strips out the non digits" do
        claim.save!
        expect(claim.teacher_reference_number).to eql("1223232")
      end
    end

    context "before the teacher reference number is stored" do
      let(:teacher_reference_number) { "12/34567" }
      it "is not modified" do
        expect(claim.teacher_reference_number).to eql("12/34567")
      end
    end
  end

  describe "#national_insurance_number" do
    it "saves with white space stripped out" do
      claim = create(:claim, national_insurance_number: "QQ 12 34 56 C")

      expect(claim.national_insurance_number).to eql("QQ123456C")
    end
  end

  describe "#student_loan_country" do
    it "captures the country the student loan was received in" do
      claim = build(:claim, student_loan_country: :england)
      expect(claim.student_loan_country).to eq("england")
    end

    it "rejects invalid countries" do
      expect { build(:claim, student_loan_country: :brazil) }.to raise_error(ArgumentError)
    end
  end

  describe "#student_loan_how_many_courses" do
    it "captures how many courses" do
      claim = build(:claim, student_loan_courses: :one_course)
      expect(claim.student_loan_courses).to eq("one_course")
    end

    it "rejects invalid responses" do
      expect { build(:claim, student_loan_courses: :one_hundred_courses) }.to raise_error(ArgumentError)
    end
  end

  describe "#no_student_loan?" do
    it "returns true if the claim has no student loan" do
      expect(build(:claim, has_student_loan: false).no_student_loan?).to eq true
      expect(build(:claim, has_student_loan: true).no_student_loan?).to eq false
    end
  end

  describe "#student_loan_country_with_one_plan?" do
    it "returns true when the student_loan_country is one with only a single student loan plan" do
      expect(build(:claim).student_loan_country_with_one_plan?).to eq false

      StudentLoan::PLAN_1_COUNTRIES.each do |country|
        expect(build(:claim, student_loan_country: country).student_loan_country_with_one_plan?).to eq true
      end
    end
  end

  describe "#policy" do
    it "returns the claim’s policy namespace" do
      expect(Claim.new(eligibility: StudentLoans::Eligibility.new).policy).to eq StudentLoans
    end

    it "returns nil if no eligibility is set" do
      expect(Claim.new.policy).to be_nil
    end
  end

  describe "#school" do
    it "returns the current_school of the claim eligiblity" do
      claim = Claim.new(eligibility: StudentLoans::Eligibility.new(current_school: schools(:penistone_grammar_school)))
      expect(claim.school).to eq schools(:penistone_grammar_school)
    end

    it "returns nil if no eligibility is set" do
      expect(Claim.new.school).to be_nil
    end
  end

  describe "#submit!" do
    around do |example|
      freeze_time { example.run }
    end

    context "when the claim is submittable" do
      let(:claim) { create(:claim, :submittable) }

      before { claim.submit! }

      it "sets submitted_at to now" do
        expect(claim.submitted_at).to eq Time.zone.now
      end

      it "generates a reference" do
        expect(claim.reference).to_not eq nil
      end
    end

    context "when a Reference clash with an existing claim occurs" do
      let(:claim) { create(:claim, :submittable) }

      before do
        other_claim = create(:claim, :submittable, reference: "12345678")
        expect(Reference).to receive(:new).once.and_return(double(to_s: other_claim.reference), double(to_s: "87654321"))
        claim.submit!
      end

      it "generates a unique reference" do
        expect(claim.reference).to eq("87654321")
      end
    end

    context "when the claim is ineligible" do
      let(:claim) { create(:claim, :ineligible) }

      before { claim.submit! }

      it "doesn't set submitted_at" do
        expect(claim.submitted_at).to be_nil
      end

      it "doesn't generate a reference" do
        expect(claim.reference).to eq nil
      end

      it "adds an error" do
        expect(claim.errors.messages[:base]).to include("You’re not eligible for this payment")
      end
    end

    context "when the claim has already been submitted" do
      let(:claim) { create(:claim, :submitted, submitted_at: 2.days.ago) }

      it "returns false" do
        expect(claim.submit!).to eq false
      end

      it "doesn't change the reference number" do
        expect { claim.submit! }.not_to(change { claim.reference })
      end

      it "doesn't change the submitted_at" do
        expect { claim.submit! }.not_to(change { claim.submitted_at })
      end
    end
  end

  describe "awaiting_checking" do
    let!(:submitted_claims) { create_list(:claim, 5, :submitted) }
    let!(:unsubmitted_claims) { create_list(:claim, 2, :submittable) }
    let!(:approved_claims) { create_list(:claim, 5, :approved) }

    it "returns submitted claims awaiting checking" do
      expect(subject.class.awaiting_checking).to match_array(submitted_claims)
    end
  end

  describe "#submittable?" do
    it "returns true when the claim is valid and has not been submitted" do
      claim = build(:claim, :submittable)

      expect(claim.submittable?).to eq true
    end
    it "returns false when it has already been submitted" do
      claim = build(:claim, :submitted)

      expect(claim.submittable?).to eq false
    end
  end

  describe "#approvable?" do
    it "returns true for a submitted claim with all required data present" do
      expect(build(:claim, :submitted).approvable?).to eq true
    end

    it "returns false for an unsubmitted claim" do
      expect(build(:claim, :submittable).approvable?).to eq false
    end

    it "returns false for a submitted claim that is missing a binary value for payroll_gender" do
      expect(build(:claim, :submitted, payroll_gender: :dont_know).approvable?).to eq false
    end

    it "returns false for a claim that already has a persisted check" do
      expect(build(:claim, :approved).approvable?).to eq true

      expect(create(:claim, :approved).approvable?).to eq false
      expect(create(:claim, :rejected).approvable?).to eq false
    end
  end

  describe "#payroll_gender_missing?" do
    it "returns true when the claimant doesn't know their payroll gender" do
      claim = build(:claim, payroll_gender: :dont_know)

      expect(claim.payroll_gender_missing?).to eq true
    end

    it "returns false when the payroll gender is one accepted by the payroll provider" do
      claim = build(:claim, payroll_gender: :female)

      expect(claim.payroll_gender_missing?).to eq false
    end
  end

  describe "#identity_confirmed?" do
    it "returns true if the claim has any GOV.UK Verified fields" do
      expect(Claim.new(verified_fields: ["payroll_gender"]).identity_confirmed?).to eq true
    end

    it "returns false if the claim doesn't have any GOV.UK Verified fields" do
      expect(Claim.new.identity_confirmed?).to eq false
      expect(Claim.new(verified_fields: []).identity_confirmed?).to eq false
    end
  end

  describe "#name_verified?" do
    it "returns true if the name is present in the list of verified fields" do
      expect(Claim.new.name_verified?).to eq false
      expect(Claim.new(verified_fields: ["first_name"]).name_verified?).to eq true
    end
  end

  describe "#address_verified?" do
    it "returns true if any address attributes are in the list of verified fields" do
      expect(Claim.new.address_verified?).to eq false
      expect(Claim.new(verified_fields: ["payroll_gender"]).address_verified?).to eq false

      expect(Claim.new(verified_fields: ["address_line_1"]).address_verified?).to eq true
      expect(Claim.new(verified_fields: ["address_line_1", "postcode"]).address_verified?).to eq true
    end
  end

  describe "#date_of_birth_verified?" do
    it "returns true if date_of_birth is in the list of verified fields" do
      expect(Claim.new(verified_fields: ["date_of_birth"]).date_of_birth_verified?).to eq true
      expect(Claim.new(verified_fields: ["address_line_1"]).date_of_birth_verified?).to eq false
    end
  end

  describe "#payroll_gender_verified?" do
    it "returns true if payroll_gender is in the list of verified fields" do
      expect(Claim.new(verified_fields: ["payroll_gender"]).payroll_gender_verified?).to eq true
      expect(Claim.new(verified_fields: ["address_line_1"]).payroll_gender_verified?).to eq false
    end
  end

  describe "#full_name" do
    it "joins the first name and surname together" do
      expect(Claim.new(first_name: "Isambard", surname: "Brunel").full_name).to eq "Isambard Brunel"
    end

    it "includes a middle name when present" do
      expect(
        Claim.new(first_name: "Isambard", middle_name: "Kingdom", surname: "Brunel").full_name
      ).to eq "Isambard Kingdom Brunel"
    end
  end

  describe "#reset_dependent_answers" do
    let(:claim) { create(:claim, :submittable) }

    it "redetermines the student_loan_plan and resets loan plan answers when has_student_loan changes" do
      claim.has_student_loan = true
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.has_student_loan = false
      claim.reset_dependent_answers

      expect(claim.has_student_loan).to eq false
      expect(claim.student_loan_country).to be_nil
      expect(claim.student_loan_courses).to be_nil
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN
    end

    it "redetermines the student_loan_plan and resets subsequent loan plan answers when student_loan_country changes" do
      claim.student_loan_country = :england
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.student_loan_country = :scotland
      claim.reset_dependent_answers
      expect(claim.has_student_loan).to eq true
      expect(claim.student_loan_country).to eq "scotland"
      expect(claim.student_loan_courses).to be_nil
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to eq StudentLoan::PLAN_1
    end

    it "redetermines the student_loan_plan and resets subsequent loan plan answers when student_loan_courses changes" do
      claim.student_loan_courses = :one_course
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.student_loan_courses = :two_or_more_courses
      claim.reset_dependent_answers
      expect(claim.has_student_loan).to eq true
      expect(claim.student_loan_country).to eq "england"
      expect(claim.student_loan_courses).to eq "two_or_more_courses"
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to be_nil
    end

    it "redetermines the student_loan_plan when the value of student_loan_start_date changes" do
      claim.student_loan_start_date = StudentLoan::BEFORE_1_SEPT_2012
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.student_loan_start_date = StudentLoan::ON_OR_AFTER_1_SEPT_2012
      claim.reset_dependent_answers
      expect(claim.has_student_loan).to eq true
      expect(claim.student_loan_country).to eq "england"
      expect(claim.student_loan_courses).to eq "one_course"
      expect(claim.student_loan_start_date).to eq StudentLoan::ON_OR_AFTER_1_SEPT_2012
      expect(claim.student_loan_plan).to eq StudentLoan::PLAN_2
    end
  end

  describe ".filtered_params" do
    it "returns a list of sensitive params to be filtered" do
      expect(Claim.filtered_params).to match_array([
        :address_line_1,
        :address_line_2,
        :address_line_3,
        :address_line_4,
        :postcode,
        :payroll_gender,
        :teacher_reference_number,
        :national_insurance_number,
        :email_address,
        :bank_sort_code,
        :bank_account_number,
        :date_of_birth,
        :first_name,
        :middle_name,
        :surname,
        :verify_response,
        :banking_name,
        :building_society_roll_number,
      ])
    end
  end

  describe "::FILTER_PARAMS" do
    it "has a value for every claim attribute" do
      expect(Claim::FILTER_PARAMS.keys).to match_array(Claim.new.attribute_names.map(&:to_sym))
    end
  end

  describe "payrollable" do
    let(:payroll_run) { create(:payroll_run, claims_counts: {StudentLoans => 1}) }
    let!(:submitted_claim) { create(:claim, :submitted) }
    let!(:first_unpayrolled_claim) { create(:claim, :approved) }
    let!(:second_unpayrolled_claim) { create(:claim, :approved) }

    it "returns approved claims that are not associated with a payroll run" do
      expect(described_class.payrollable).to match_array([first_unpayrolled_claim, second_unpayrolled_claim])
    end
  end

  describe "#scheduled_payment_date" do
    let(:scheduled_payment_date) { Date.parse("2019-01-01") }
    let(:claim) { create(:claim, :submitted) }

    context "when a claim has a payroll run associated with it" do
      let!(:payment) { create(:payment, :with_figures, claims: [claim], scheduled_payment_date: scheduled_payment_date) }

      it "returns the payment date" do
        expect(claim.scheduled_payment_date).to eq(scheduled_payment_date)
      end
    end

    context "when a claim does not have a payroll run associated with it" do
      it "returns nil" do
        expect(claim.scheduled_payment_date).to be_nil
      end
    end
  end
end
