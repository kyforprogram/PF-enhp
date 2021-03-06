class Users::DirectMessagesController < ApplicationController
before_action :authenticate_user!

  def index
    my_entry_rooms= current_user.entries.pluck(:room_id)
    @entries = Entry.includes(:room, :user).where(room_id: my_entry_rooms).where.not(user_id: current_user)
  end

  def show
    @user = User.find(params[:id])# どのユーザーとチャットするかを取得。
    rooms = current_user.entries.pluck(:room_id)# カレントユーザーのuser_roomにあるroom_idの値の配列をroomsに代入。
    entries = Entry.find_by(user_id: @user.id, room_id: rooms)

    unless entries.nil?#以前そのユーザーと話したことがあるかないか
      @room = entries.room#Entryモデルに既にデータがある場合は@roomに既存のentries.roomを代入
    else
      @room = Room.new#以前そのユーザーと話したことがない場合は新しいroomを作る
      @room.save
      Entry.create(user_id: current_user.id, room_id: @room.id)
      Entry.create(user_id: @user.id, room_id: @room.id)
    end

    @direct_messages = @room.direct_messages.order(created_at: :desc)
    @direct_messages = Kaminari.paginate_array(@direct_messages).page(params[:page]).per(8)
    @direct_message = DirectMessage.new(room_id: @room.id)
  end

  def create
    @direct_message = current_user.direct_messages.new(direct_message_params)
    @direct_message.save
    #redirect_to request.referer
    @room = Room.find(params[:direct_message][:room_id])
    @direct_messages = @room.direct_messages.order(created_at: :desc)
  end

  private

  def direct_message_params
    params.require(:direct_message).permit(:message, :room_id)
  end
end
