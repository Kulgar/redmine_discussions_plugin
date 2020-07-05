class DiscussionsController < ApplicationController
  before_action :set_project, :authorize
  before_action :set_priorities, except: [:index, :show, :destroy]
  before_action :set_discussion, only: [:show, :edit, :update, :destroy]

  accept_api_auth :index

  # GET /discussions
  # GET /discussions.json
  # GET /discussions.xml
  def index
    @discussions = @project.discussions

    respond_to do |format|
      format.html
      format.api
    end
  end

  # GET /discussions/1
  # GET /discussions/1.json
  def show
    @answer  = @discussion.answers.build
    @answers = @discussion.answers.where.not(id: nil)
  end

  # GET /discussions/new
  def new
    @discussion = @project.discussions.build(author_id: User.current.id)
  end

  # GET /discussions/1/edit
  def edit
  end

  # POST /discussions
  # POST /discussions.json
  def create
    @discussion = @project.discussions.build(discussion_params.merge(author_id: User.current.id))

    respond_to do |format|
      if @discussion.save
        format.html { redirect_to [@project, @discussion], notice: 'Discussion was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /discussions/1
  # PATCH/PUT /discussions/1.json
  def update
    respond_to do |format|
      if @discussion.editable? && @discussion.update(discussion_params)
        format.html { redirect_to [@project, @discussion], notice: 'Discussion was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /discussions/1
  # DELETE /discussions/1.json
  def destroy
    respond_to do |format|
      if @discussion.editable?
        @discussion.destroy
        format.html { redirect_to project_discussions_url(@project), notice: 'Discussion was successfully destroyed.' }
      else
        format.html { redirect_to project_discussions_url(@project), alert: "You can't delete that discussion." }
      end
    end
  end

  private
    def set_project
      # @project variable must be set before calling the authorize filter
      @project = Project.find(params[:project_id])
    end

    def set_priorities
      @priorities = IssuePriority.active
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_discussion
      @discussion = Discussion.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def discussion_params
      params.require(:discussion).permit(:subject, :content, :project_id, :priority_id, :author_id)
    end
end
