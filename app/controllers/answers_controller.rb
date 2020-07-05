class AnswersController < ApplicationController
  before_action :set_discussion
  before_action :set_answer, only: [:edit, :update, :destroy]

  # GET /answers/1/edit
  def edit
  end

  # POST /answers
  # POST /answers.json
  def create
    @answer = @discussion.answers.build(answer_params)
    @answer.author = User.current

    respond_to do |format|
      if @answer.save
        format.html { redirect_to @discussion, notice: 'Answer was successfully created.' }
        format.json { render :show, status: :created, location: @answer }
      else
        format.html { render "discussions/show" }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /answers/1
  # PATCH/PUT /answers/1.json
  def update
    respond_to do |format|
      if @answer.update(answer_params)
        format.html { redirect_to @discussion, notice: 'Answer was successfully updated.' }
        format.json { render :show, status: :ok, location: @answer }
      else
        format.html { render :edit }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /answers/1
  # DELETE /answers/1.json
  def destroy
    @answer.destroy
    respond_to do |format|
      format.html { redirect_to @discussion, notice: 'Answer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
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
