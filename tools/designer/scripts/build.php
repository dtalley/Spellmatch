<?php
	
	$minify = true;
	foreach($argv as $arg)
	{
		if( $arg == "-d" )
		{
			$minify = false;
		}
	}

	$idir = "../build";
	$odir = "../output";
	$bfile = $idir . "/build.json";
	$fp = fopen($bfile, "r");
	$json = fread($fp, filesize($bfile));
	fclose($fp);
	$list = json_decode($json, true);
	
	foreach( $list as $section )
	{
		$ofile = $odir . "/" . $section["output"];

		$ifiles = array();
		foreach( $section["inputs"] as $file )
		{
			$ifiles[] = $idir . "/" . $file;
		}

		compress_resources( $ofile, $ifiles );
	}

	echo "All files successfully compressed...\n";




	/*******************************************************************
	 *******************************************************************
	 *******************************************************************
	 * 
	 * Utility functions that handle compression and minification.
	 *
	 * Shouldn't need to modify anything beyond this point.
	 * 
	 *******************************************************************
	 *******************************************************************
	 *******************************************************************/

	/*
	 * Compress a given set of files according to their types, which
	 * means minifying them, combining them all into one file, and
	 * copying that file to the specified output file.
	 */
	function compress_resources($output, $files)
	{
		global $minify;
		$string = "";
		foreach( $files as $file )
		{
			if( substr( $file, -4 ) == "scss" || substr( $file, -3 ) == "css" )
			{
				$type = "css";
			}
			else if( substr( $file, -4 ) == "html" )
			{
				$type = "html";
			}
			else if( substr( $file, -2 ) == "js" )
			{
				$type = "js";
			}
			$delete = false;
			if( substr( $file, -4 ) == "scss" )
			{
				echo "Converting SASS stylesheet: " . $file . "...\n";
				$converted = substr( $file, 0, strlen($file) - 4 ) . "css";
				exec( "sass " . $file . " " . $converted );
				if( file_exists( $converted ) )
				{
					$file = $converted;
					$delete = true;
				}
			}
			echo "Processing resource: " . $file . "...\n";
			if( substr($file, 0 - strlen($type) - 4, strlen($type) + 4) == "min.$type" || !$minify )
			{
				$fp = fopen($file, "r");
				if( $fp )
				{
					$body = fread($fp, filesize($file));
					fclose($fp);
					if( strlen($string) > 0 )
					{
						$string .= "\r\n";
					}
					$string .= $body;
				}
			}
			else
			{
				if( $type == "css" || $type == "js" )
				{
					exec( "java -jar yuicompressor-2.4.8pre.jar -o tempfile.$type " . $file );
				}
				else if( $type == "html" )
				{
					exec( "java -jar htmlcompressor-1.5.3.jar -o tempfile.$type " . $file );
				}
				if( file_exists("tempfile.$type") )
				{
					$fp = fopen("tempfile.$type", "r");
					if( $fp )
					{
						$body = fread($fp, filesize("tempfile.$type"));
						fclose($fp);
						unlink("tempfile.$type");
						if( strlen($string) > 0 )
						{
							$string .= "\r\n";
						}
						$string .= $body;
					}
				}
			}
			if( $delete )
			{
				unlink($file);
			}
		}

		if( $minify )
		{
			process_string($string);
		}
		$fp = fopen($output, "w");
		if($fp)
		{
			fwrite($fp, $string, strlen($string));
			fclose($fp);
		}
	}

	/*
	 * Remove comments and unnecessary white space from a string
	 */
	function process_string(&$string)
	{
		$string = preg_replace( "!^\\s*//(.*?)\$!sim", "", $string );
		$string = preg_replace( "/\\/\\*(.*?)\\*\\//si", "", $string );
		$string = preg_replace( "/\n/si", "", $string );
		$string = preg_replace( "/\r/si", "", $string );
		$string = preg_replace( "/\r\n/si", "", $string );
	}

?>