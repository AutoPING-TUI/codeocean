# frozen_string_literal: true

module ProformaService
  class ConvertTaskToExercise < ServiceBase
    def initialize(task:, user:, exercise: nil)
      super()
      @task = task
      @user = user
      @exercise = exercise || Exercise.new(unpublished: true)
    end

    def execute
      import_exercise
      @exercise
    end

    private

    def import_exercise
      @exercise.assign_attributes(
        user: @user,
        title: @task.title,
        description: @task.description,
        public: @task.meta_data[:CodeOcean]&.dig(:public) == 'true',
        hide_file_tree: @task.meta_data[:CodeOcean]&.dig(:hide_file_tree) == 'true',
        allow_file_creation: @task.meta_data[:CodeOcean]&.dig(:allow_file_creation) == 'true',
        allow_auto_completion: @task.meta_data[:CodeOcean]&.dig(:allow_auto_completion) == 'true',
        expected_difficulty: @task.meta_data[:CodeOcean]&.dig(:expected_difficulty),
        execution_environment_id: @task.meta_data[:CodeOcean]&.dig(:execution_environment_id),

        files: files
      )
    end

    def files
      model_solution_files + test_files + task_files.values
    end

    def test_files
      @task.tests.map do |test_object|
        task_files.delete(test_object.files.first.id).tap do |file|
          file.weight = test_object.meta_data[:CodeOcean]&.dig(:weight) || 1.0
          file.feedback_message = test_object.meta_data[:CodeOcean]&.dig(:'feedback-message').presence || 'Feedback'
          file.role = 'teacher_defined_test'
        end
      end
    end

    def model_solution_files
      @task.model_solutions.map do |model_solution_object|
        task_files.delete(model_solution_object.files.first.id).tap do |file|
          file.role = 'reference_implementation'
        end
      end
    end

    def task_files
      @task_files ||= @task.all_files.reject {|file| file.id == 'ms-placeholder-file' }.to_h do |task_file|
        [task_file.id, codeocean_file_from_task_file(task_file)]
      end
    end

    def codeocean_file_from_task_file(file)
      extension = File.extname(file.filename)
      codeocean_file = CodeOcean::File.new(
        context: @exercise,
        file_type: file_type(extension),
        hidden: file.visible == 'no',
        name: File.basename(file.filename, '.*'),
        read_only: file.usage_by_lms != 'edit',
        role: 'regular_file',
        path: File.dirname(file.filename).in?(['.', '']) ? nil : File.dirname(file.filename)
      )
      if file.binary
        codeocean_file.native_file = FileIO.new(file.content.dup.force_encoding('UTF-8'), File.basename(file.filename))
      else
        codeocean_file.content = file.content
      end
      codeocean_file
    end

    def file_type(extension)
      FileType.find_or_create_by(file_extension: extension) do |file_type|
        file_type.name = extension[1..]
        file_type.user = @user
        file_type.indent_size = 4
        file_type.editor_mode = 'ace/mode/plain_text'
      end
    end
  end
end
