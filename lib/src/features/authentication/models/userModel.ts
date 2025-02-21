import mongoose, { Document, Schema } from 'mongoose';

// 定义 UserModel 接口
interface IUser extends Document {
  username: string;
  email: string;
  phoneNumber: string;
  profilePicture: string;
  formattedPhoneNo: string;
}

// 定义 User Schema
const UserSchema = new Schema<IUser>({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phoneNumber: { type: String, required: true },
  profilePicture: { type: String, required: false, default: '' },
});

// 格式化电话号码的方法
UserSchema.virtual('formattedPhoneNo').get(function (this: IUser) {
  return formatPhoneNumber(this.phoneNumber); // 你需要实现 formatPhoneNumber 方法
});

// 静态方法: 创建空的用户对象
UserSchema.statics.empty = function (): IUser {
  return new this({
    username: '',
    email: '',
    phoneNumber: '',
    profilePicture: '',
  });
};

const UserModel = mongoose.model<IUser>('User', UserSchema);
export default UserModel;