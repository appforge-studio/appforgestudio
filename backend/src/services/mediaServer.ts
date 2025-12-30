import { promises as fs } from 'node:fs';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { execSync } from 'node:child_process';
import ffmpeg from 'fluent-ffmpeg';

export interface UploadResult {
	url: string;
	rawUrl?: string;
	coverImageUrl?: string;
	duration?: number; // Duration in seconds
	path: string;
	originalName: string;
	contentType?: string;
}

export interface UploadInput {
    originalName: string;
    bytes: Buffer;
    contentType: string | undefined;
    directory: string | undefined;
}

export class MediaServer {
	private readonly uploadRoot: string;

	constructor(uploadRootDir?: string) {
		this.uploadRoot = uploadRootDir ?? path.resolve(process.cwd(), 'uploads');
	}

	public async uploadMedia(input: UploadInput): Promise<UploadResult> {
		console.log("got upload request");
		const { originalName, bytes, contentType, directory } = input;
		const targetDir = directory ? path.join(this.uploadRoot, directory) : this.uploadRoot;
		await this.ensureDirectory(targetDir);

		const ext = this.getSafeExtension(originalName);
		const fileName = `${randomUUID()}${ext}`;
		const absolutePath = path.join(targetDir, fileName);

		await fs.writeFile(absolutePath, bytes);

		// For audio files, convert to Opus and return both URLs
		if (this.isAudioFile(contentType, ext)) {
			console.log("Audio file detected, saving raw file");
			const rawFileUrl = `/uploads/${directory ? `${directory}/` : ''}${fileName}`;

			let duration: number | undefined;

			// Extract audio duration if FFmpeg is available
			if (this.isFFmpegAvailable()) {
				try {
					duration = await this.getAudioDuration(absolutePath);
					console.log("Audio duration extracted:", duration, "milliseconds");
				} catch (error) {
					console.error("Audio duration extraction failed:", error);
				}
			}

			// Skip Opus conversion if uploading to a 'raw' directory
			const shouldConvertToOpus = !directory?.includes('raw');

			if (shouldConvertToOpus && this.isFFmpegAvailable()) {
				console.log("FFmpeg available, attempting Opus conversion");
				try {
					const opusResult = await this.convertToOpus(absolutePath, targetDir, fileName);
					console.log("Opus conversion successful, returning both URLs");
					return {
						url: opusResult.url,
						rawUrl: rawFileUrl,
						duration,
						path: opusResult.path,
						originalName,
						contentType: 'audio/ogg', // Opus in Ogg container
					};
				} catch (error) {
					console.error("Opus conversion failed, returning raw file URL as main URL:", error);
					return {
						url: rawFileUrl,
						rawUrl: rawFileUrl,
						duration,
						path: absolutePath,
						originalName,
						...(contentType !== undefined ? { contentType } : {}),
					};
				}
			} else {
				console.log("FFmpeg not available or raw upload, returning raw file URL");
				return {
					url: rawFileUrl,
					rawUrl: rawFileUrl,
					duration,
					path: absolutePath,
					originalName,
					...(contentType !== undefined ? { contentType } : {}),
				};
			}
		}

		// For video files, return both HLS and raw URLs unless uploading to raw directory
		if (this.isVideoFile(contentType, ext)) {
			console.log("Video file detected, saving raw file");
			const rawFileUrl = `/uploads/${directory ? `${directory}/` : ''}${fileName}`;

			let coverImageUrl: string | undefined;
			let duration: number | undefined;

			// Extract cover image and duration if FFmpeg is available
			if (this.isFFmpegAvailable()) {
				try {
					coverImageUrl = await this.extractCoverImage(absolutePath, targetDir, fileName);
					console.log("Cover image extracted:", coverImageUrl);
				} catch (error) {
					console.error("Cover image extraction failed:", error);
				}

				try {
					duration = await this.getVideoDuration(absolutePath);
					console.log("Video duration extracted:", duration, "seconds");
				} catch (error) {
					console.error("Duration extraction failed:", error);
				}
			}

			// Skip HLS conversion if uploading to a 'raw' directory
			const shouldConvertToHLS = !directory?.includes('raw');

			if (shouldConvertToHLS && this.isFFmpegAvailable()) {
				console.log("FFmpeg available, attempting HLS conversion");
				try {
					const hlsResult = await this.convertToHLS(absolutePath, targetDir, fileName);
					console.log("HLS conversion successful, returning both URLs");
					return {
						url: hlsResult.url,
						rawUrl: rawFileUrl,
						coverImageUrl,
						duration,
						path: hlsResult.path,
						originalName,
						contentType: 'application/x-mpegURL', // HLS manifest MIME type
					};
				} catch (error) {
					console.error("HLS conversion failed, returning raw file URL as main URL:", error);
					// Fall back to raw file as main URL if HLS conversion fails
					return {
						url: rawFileUrl,
						rawUrl: rawFileUrl,
						coverImageUrl,
						duration,
						path: absolutePath,
						originalName,
						...(contentType !== undefined ? { contentType } : {}),
					};
				}
			} else {
				console.log("FFmpeg not available or raw upload, returning raw file URL");
				return {
					url: rawFileUrl,
					rawUrl: rawFileUrl,
					coverImageUrl,
					duration,
					path: absolutePath,
					originalName,
					...(contentType !== undefined ? { contentType } : {}),
				};
			}
		}

		// For non-video files, return the original file URL
		const fileUrl = `/uploads/${directory ? `${directory}/` : ''}${fileName}`;

		return {
			url: fileUrl,
			path: absolutePath,
			originalName,
			...(contentType !== undefined ? { contentType } : {}),
		};
	}

	private async ensureDirectory(dir: string): Promise<void> {
		try {
			await fs.mkdir(dir, { recursive: true });
		} catch (_) {
			// noop: mkdir with recursive handles existing dirs
		}
	}

	private isVideoFile(contentType?: string, extension?: string): boolean {
		if (contentType && contentType.startsWith('video/')) return true;
		if (extension && /^\.(mp4|mov|m4v|avi|mkv|webm|flv|wmv)$/.test(extension)) return true;
		return false;
	}

	private isAudioFile(contentType?: string, extension?: string): boolean {
		if (contentType && contentType.startsWith('audio/')) return true;
		if (extension && /^\.(mp3|wav|ogg|m4a|aac|flac|wma)$/.test(extension)) return true;
		return false;
	}

	private isFFmpegAvailable(): boolean {
		try {
			execSync('ffmpeg -version', { stdio: 'ignore' });
			return true;
		} catch (error) {
			return false;
		}
	}

	private async convertToHLS(inputPath: string, targetDir: string, fileName: string): Promise<UploadResult> {
		return new Promise((resolve, reject) => {
			const baseName = path.parse(fileName).name;
			const hlsDir = path.join(targetDir, baseName);
			const manifestPath = path.join(hlsDir, 'playlist.m3u8');

			console.log('Starting HLS conversion...');
			console.log('Input path:', inputPath);
			console.log('HLS directory:', hlsDir);
			console.log('Manifest path:', manifestPath);

			// Ensure HLS directory exists
			this.ensureDirectory(hlsDir).then(() => {
				console.log('HLS directory created, starting FFmpeg conversion');

				// Set FFmpeg path if available
				try {
					ffmpeg.setFfmpegPath('ffmpeg');
				} catch (e) {
					console.log('Using default FFmpeg path');
				}

				ffmpeg(inputPath)
					.inputOptions(['-hwaccel auto'])
					.outputOptions([
						'-c:v h264',
						'-c:a aac',
						'-b:v 1000k',
						'-b:a 128k',
						'-hls_time 10',
						'-hls_list_size 0',
						'-f hls',
						'-hls_segment_filename', path.join(hlsDir, 'segment_%03d.ts')
					])
					.output(manifestPath)
					.on('start', (commandLine: any) => {
						console.log('FFmpeg command: ' + commandLine);
					})
					.on('progress', (progress: any) => {
						console.log('FFmpeg progress: ' + progress.percent + '% done');
					})
					.on('end', () => {
						console.log('HLS conversion completed successfully');
						const hlsUrl = `/uploads/${path.relative(this.uploadRoot, hlsDir).replace(/\\/g, '/')}/playlist.m3u8`;
						console.log('HLS URL:', hlsUrl);
						resolve({
							url: hlsUrl,
							path: manifestPath,
							originalName: fileName,
							contentType: 'application/x-mpegURL'
						});
					})
					.on('error', (err: Error) => {
						console.error('HLS conversion failed:', err);
						reject(err);
					})
					.run();
			}).catch((err: Error) => {
				console.error('Failed to create HLS directory:', err);
				reject(err);
			});
		});
	}

	private async extractCoverImage(inputPath: string, targetDir: string, fileName: string): Promise<string> {
		return new Promise((resolve, reject) => {
			const baseName = path.parse(fileName).name;
			const coverImagePath = path.join(targetDir, `${baseName}_cover.jpg`);

			console.log('Extracting cover image...');
			console.log('Input path:', inputPath);
			console.log('Cover image path:', coverImagePath);

			// Set FFmpeg path if available
			try {
				ffmpeg.setFfmpegPath('ffmpeg');
			} catch (e) {
				console.log('Using default FFmpeg path');
			}

			ffmpeg(inputPath)
				.inputOptions(['-ss', '00:00:01']) // Seek to 1 second to avoid black frames
				.outputOptions(['-vframes', '1', '-q:v', '2']) // Extract 1 frame with high quality
				.output(coverImagePath)
				.on('start', (commandLine: any) => {
					console.log('FFmpeg cover extraction command: ' + commandLine);
				})
				.on('end', () => {
					console.log('Cover image extraction completed successfully');
					const coverImageUrl = `/uploads/${path.relative(this.uploadRoot, coverImagePath).replace(/\\/g, '/')}`;
					console.log('Cover image URL:', coverImageUrl);
					resolve(coverImageUrl);
				})
				.on('error', (err: Error) => {
					console.error('Cover image extraction failed:', err);
					reject(err);
				})
				.run();
		});
	}

	private async getVideoDuration(inputPath: string): Promise<number> {
		return new Promise((resolve, reject) => {
			ffmpeg.ffprobe(inputPath, (err, metadata) => {
				if (err) {
					reject(err);
					return;
				}
				const duration = metadata.format.duration;
				if (duration) {
					resolve(Math.round(duration));
				} else {
					reject(new Error('Duration not found in video metadata'));
				}
			});
		});
	}

	private async getAudioDuration(inputPath: string): Promise<number> {
		return new Promise((resolve, reject) => {
			ffmpeg.ffprobe(inputPath, (err, metadata) => {
				if (err) {
					reject(err);
					return;
				}
				const duration = metadata.format.duration;
				if (duration) {
					resolve(Math.round(duration * 1000)); // Return duration in milliseconds
				} else {
					reject(new Error('Duration not found in audio metadata'));
				}
			});
		});
	}

	private async convertToOpus(inputPath: string, targetDir: string, fileName: string): Promise<UploadResult> {
		return new Promise((resolve, reject) => {
			const baseName = path.parse(fileName).name;
			const opusFileName = `${baseName}.opus`;
			const opusPath = path.join(targetDir, opusFileName);

			console.log('Starting Opus conversion...');
			console.log('Input path:', inputPath);
			console.log('Output path:', opusPath);

			try {
				ffmpeg.setFfmpegPath('ffmpeg');
			} catch (e) {
				console.log('Using default FFmpeg path');
			}

			ffmpeg(inputPath)
				.audioCodec('libopus')
				.audioBitrate('64k')
				.audioChannels(1)
				.audioFrequency(48000)
				.outputOptions(['-vn']) // No video
				.output(opusPath)
				.on('start', (commandLine: any) => {
					console.log('FFmpeg command: ' + commandLine);
				})
				.on('progress', (progress: any) => {
					console.log('FFmpeg progress: ' + progress.percent + '% done');
				})
				.on('end', () => {
					console.log('Opus conversion completed successfully');
					const opusUrl = `/uploads/${path.relative(this.uploadRoot, opusPath).replace(/\\/g, '/')}`;
					console.log('Opus URL:', opusUrl);
					resolve({
						url: opusUrl,
						path: opusPath,
						originalName: fileName,
						contentType: 'audio/ogg'
					});
				})
				.on('error', (err: Error) => {
					console.error('Opus conversion failed:', err);
					reject(err);
				})
				.run();
		});
	}

	private getSafeExtension(fileName: string): string {
		const idx = fileName.lastIndexOf('.');
		if (idx === -1) return '';
		const ext = fileName.slice(idx).toLowerCase();
		// Basic allowlist for common media types; fallback to empty if suspicious
		if (/^\.(png|jpg|jpeg|gif|webp|mp4|mov|m4v|mp3|wav|ogg|m4a|aac|flac|opus|heic|heif|pdf)$/.test(ext)) return ext;
		return '';
	}
}

export const mediaServer = new MediaServer();


