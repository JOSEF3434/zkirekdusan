import dotenv from 'dotenv';
dotenv.config();
import { v2 as cloudinary } from 'cloudinary';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

async function main() {
  console.log('Cloud name:', process.env.CLOUDINARY_CLOUD_NAME);
  try {
    const resImage = await cloudinary.api.resources({
      type: 'upload',
      resource_type: 'image',
      max_results: 30,
    });
    console.log('Images in cloudinary:', resImage.resources.map(r => ({
      public_id: r.public_id,
      format: r.format,
      secure_url: r.secure_url,
      resource_type: r.resource_type,
    })));
  } catch (e) {
    console.error('Error fetching images:', e);
  }

  try {
    const resRaw = await cloudinary.api.resources({
      type: 'upload',
      resource_type: 'raw',
      max_results: 30,
    });
    console.log('Raw resources in cloudinary:', resRaw.resources.map(r => ({
      public_id: r.public_id,
      format: r.format,
      secure_url: r.secure_url,
      resource_type: r.resource_type,
    })));
  } catch (e) {
    console.error('Error fetching raw:', e);
  }
}

main();
