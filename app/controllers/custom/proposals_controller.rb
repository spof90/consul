require_dependency Rails.root.join("app", "controllers", "proposals_controller").to_s

class ProposalsController
  include ProposalsHelper

  before_action(except: [:json_data]) {authenticate_user!}
  before_action :redirect, only: :index

  load_and_authorize_resource except: :json_data

  skip_authorization_check only: :json_data

  def redirect
    if (!params[:search].present? || !Tag.category_names.include?(params[:search])) &&
      (!current_user.present? || !(current_user.moderator? || current_user.administrator?)) then
        redirect_to "/"
    end
  end

  def create
    @proposal = Proposal.new(proposal_params.merge(author: current_user))
    if @proposal.save
      redirect_to created_proposal_path(@proposal), notice: I18n.t("flash.actions.create.proposal")
    else
      render :new
    end
  end

  def index_customization
    discard_draft
    discard_archived
    load_retired
    load_selected
    load_featured
    remove_archived_from_order_links
    @proposals_coordinates = all_proposal_map_locations
  end

  def json_data
    proposal = Proposal.find(params[:id])
    data = {
      proposal_id: proposal.id,
      proposal_title: proposal.title
    }.to_json

    respond_to do |format|
      format.json { render json: data }
    end
  end

end