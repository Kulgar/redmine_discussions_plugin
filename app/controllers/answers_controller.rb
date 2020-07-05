class AnswersController < ApplicationController
  before_action :set_project, :authorize

  before_action :set_discussion
  before_action :set_answer, only: [:edit, :update, :destroy]

  # GET /answers/1/edit
  def edit
    unless @answer.editable?
      redirect_to [@project, @discussion], alert: "You can't edit that answer"
    end
  end

  # POST /answers
  # POST /answers.json
  def create
    @answer = @discussion.answers.build(answer_params)
    @answer.author = User.current

    respond_to do |format|
      if Answer.creatable?(@project) && @answer.save
        format.html { redirect_to [@project, @discussion], notice: 'Answer was successfully created.' }
      else
        format.html { render "discussions/show" }
      end
    end
  end

  # PATCH/PUT /answers/1
  # PATCH/PUT /answers/1.json
  def update
    respond_to do |format|
      if @answer.editable? && @answer.update(answer_params)
        format.html { redirect_to [@project, @discussion], notice: 'Answer was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /answers/1
  # DELETE /answers/1.json
  def destroy

    respond_to do |format|
      if @answer.editable?
        @answer.destroy
        format.html { redirect_to [@project, @discussion], notice: 'Answer was successfully destroyed.' }
      else
        format.html { redirect_to [@project, @discussion], notice: "You can't delete that answer" }
      end
    end
  end

  private
    def set_project
      @project = Project.find(params[:project_id])
    end

    def set_discussion
      @discussion = Discussion.find(params[:discussion_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_answer
      @answer = @discussion.answers.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def answer_params
      params.require(:answer).permit(:content)
    end
end
